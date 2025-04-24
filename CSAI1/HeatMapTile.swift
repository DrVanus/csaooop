import SwiftUI
import Combine
// import Foundation


// MARK: - Tile Model
struct HeatMapTile: Identifiable, Equatable, Decodable {
    let id = UUID()
    let symbol: String
    let pctChange: Double
    let marketCap: Double

    private enum CodingKeys: String, CodingKey {
        case symbol
        case pctChange = "price_change_percentage_24h"
        case marketCap = "market_cap"
    }
}

// MARK: - Helper Functions
/// Maps -10%…+10% change to red–green hue
private func color(for pct: Double) -> Color {
    let capped = min(max(pct, -10), 10)
    let t = (capped + 10) / 20   // 0…1
    return Color(hue: 0.33 * t, saturation: 0.8, brightness: 0.9)
}

/// Simple alternating slice-and-dice treemap
private func sliceDice(
    items: [HeatMapTile],
    weights: [Double],
    rect: CGRect,
    horizontal: Bool = true
) -> [CGRect] {
    guard !items.isEmpty else { return [] }
    if items.count == 1 {
        return [rect]
    }
    let total = weights.reduce(0, +)
    let frac = total > 0 ? weights[0] / total : 0
    let firstRect: CGRect
    let restRect: CGRect
    if horizontal {
        let w = rect.width * CGFloat(frac)
        firstRect = CGRect(x: rect.minX, y: rect.minY, width: w, height: rect.height)
        restRect = CGRect(x: rect.minX + w, y: rect.minY, width: rect.width - w, height: rect.height)
    } else {
        let h = rect.height * CGFloat(frac)
        firstRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: h)
        restRect = CGRect(x: rect.minX, y: rect.minY + h, width: rect.width, height: rect.height - h)
    }
    let remainingRects = sliceDice(
        items: Array(items.dropFirst()),
        weights: Array(weights.dropFirst()),
        rect: restRect,
        horizontal: !horizontal
    )
    return [firstRect] + remainingRects
}

// MARK: - Treemap View
struct TreemapView: View {
    let tiles: [HeatMapTile]
    /// Spacing between tiles
    var tileSpacing: CGFloat = 1
    /// Minimum area to show labels
    var labelThreshold: CGFloat = 800
    /// Animate layout updates
    var animationDuration: Double = 0.5
    /// Show legend below the map
    var showLegend: Bool = true

    /// Number of top coins to display individually; the rest group into “Others”
    var topCount: Int = 10

    private var displayTiles: [HeatMapTile] {
        let sortedAll = tiles.sorted { $0.marketCap > $1.marketCap }
        // Always show the top N coins
        let topTiles = Array(sortedAll.prefix(topCount))
        let smallTiles = sortedAll.dropFirst(topCount)

        var result = topTiles
        if !smallTiles.isEmpty {
            let othersCap = smallTiles.reduce(0) { $0 + $1.marketCap }
            let weightedSum = smallTiles.reduce(0) { $0 + $1.pctChange * $1.marketCap }
            let othersPct = othersCap > 0 ? weightedSum / othersCap : 0
            result.append(HeatMapTile(symbol: "Others", pctChange: othersPct, marketCap: othersCap))
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // DEBUG: show count of display tiles
            Text("Display Tiles: \(displayTiles.count)")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.leading, 8)
            GeometryReader { geo in
                Canvas { context, size in
                    // Use slice-and-dice treemap layout
                    let weights = displayTiles.map { $0.marketCap }
                    let rects = sliceDice(
                        items: displayTiles,
                        weights: weights,
                        rect: CGRect(origin: .zero, size: size),
                        horizontal: false
                    )
                    for (tile, rect) in zip(displayTiles, rects) {
                        let insetRect = rect.insetBy(dx: tileSpacing/2, dy: tileSpacing/2)
                        // background
                        context.fill(Path(insetRect), with: .color(color(for: tile.pctChange)))
                        // label if area large enough
                        let area = insetRect.width * insetRect.height
                        if area > labelThreshold {
                            var attr = AttributedString("\(tile.symbol)\n\(String(format: "%+.1f%%", tile.pctChange))")
                            attr.foregroundColor = .white
                            attr.font = .system(size: min(insetRect.width, insetRect.height) * 0.15, weight: .bold)
                            let text = Text(attr)
                            context.draw(text, at: CGPoint(x: insetRect.midX, y: insetRect.midY))
                        }
                    }
                }
                .animation(.easeInOut(duration: animationDuration), value: tiles)
            }
            if showLegend {
                HStack(spacing: 8) {
                    Text("-10%").font(.caption2).foregroundColor(.white)
                    Rectangle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.red, Color.green]),
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(height: 8)
                        .cornerRadius(4)
                    Text("+10%").font(.caption2).foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Heat Map ViewModel

class HeatMapViewModel: ObservableObject {
    @Published var tiles: [HeatMapTile] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        fetchHeatMapData()
        // Refresh every 60 seconds
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.fetchHeatMapData() }
            .store(in: &cancellables)
    }

    func fetchHeatMapData() {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&sparkline=false&price_change_percentage=24h") else { return }
        URLSession.shared.dataTaskPublisher(for: url)
            .retry(2) // retry up to 2 times on failure
            .map(\.data)
            .decode(type: [HeatMapTile].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case let .failure(error) = completion {
                    print("HeatMap fetch error:", error)
                }
            } receiveValue: { [weak self] tiles in
                print("HeatMap fetched:", tiles.count)
                self?.tiles = tiles
            }
            .store(in: &cancellables)
    }
}
