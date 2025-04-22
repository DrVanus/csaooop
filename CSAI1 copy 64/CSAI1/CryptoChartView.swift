// Live window duration in seconds for the live chart interval
private let liveWindow: TimeInterval = 300
import Foundation
import SwiftUI
import Charts
import Combine

// MARK: – Data Model
struct ChartDataPoint: Identifiable, Equatable {
    let id    = UUID()
    let date  : Date
    let close : Double
}

// MARK: – Interval Enum
enum ChartInterval: String, CaseIterable {
    case live = "LIVE"
    case oneMin = "1m", fiveMin = "5m", fifteenMin = "15m", thirtyMin = "30m"
    case oneHour = "1H", fourHour = "4H", oneDay = "1D", oneWeek = "1W"
    case oneMonth = "1M", threeMonth = "3M", oneYear = "1Y", threeYear = "3Y", all = "ALL"
    
    var binanceInterval: String {
        switch self {
        case .live:      return "1m"
        case .oneMin:     return "1m"
        case .fiveMin:    return "5m"
        case .fifteenMin: return "15m"
        case .thirtyMin:  return "30m"
        case .oneHour:    return "1h"
        case .fourHour:   return "4h"
        case .oneDay:     return "1d"
        case .oneWeek:    return "1w"
        case .oneMonth:   return "1M"
        case .threeMonth, .oneYear, .threeYear: return "1d"
        case .all:        return "1w"
        }
    }
    var binanceLimit: Int {
        switch self {
        case .live:      return Int(liveWindow)
        case .oneMin:     return 60
        case .fiveMin:    return 48
        case .fifteenMin: return 24
        case .thirtyMin:  return 24
        case .oneHour:    return 48
        case .fourHour:   return 120
        case .oneDay:     return 60
        case .oneWeek:    return 52
        case .oneMonth:   return 12
        case .threeMonth: return 90
        case .oneYear:    return 365
        case .threeYear:  return 1095
        case .all:        return 999
        }
    }
    var hideCrosshairTime: Bool {
        switch self {
        case .oneWeek, .oneMonth, .threeMonth, .oneYear, .threeYear, .all:
            return true
        default:
            return false
        }
    }
}

// MARK: – ViewModel
class CryptoChartViewModel: ObservableObject {
    @Published var dataPoints   : [ChartDataPoint] = []
    @Published var isLoading    = false
    @Published var errorMessage : String? = nil

    private var lastLiveUpdate: Date = .init(timeIntervalSince1970: 0)

    // Combine throttling for live data
    private var liveSubject = PassthroughSubject<ChartDataPoint, Never>()
    private var cancellables = Set<AnyCancellable>()

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 10
        cfg.timeoutIntervalForResource = 10
        return URLSession(configuration: cfg)
    }()

    private var liveSocket: URLSessionWebSocketTask? = nil

    init() {
        liveSubject
            .throttle(for: .seconds(1), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] pt in
                guard let self = self else { return }
                self.dataPoints.append(pt)
                if self.dataPoints.count > Int(liveWindow) {
                    self.dataPoints.removeFirst()
                }
                self.isLoading = false
            }
            .store(in: &cancellables)
    }

    func startLive(symbol: String) {
        let stream = (symbol + "USDT").lowercased() + "@trade"
        // Reset state and show loading before starting live socket
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            self.dataPoints.removeAll()
        }
        liveSocket = URLSession.shared.webSocketTask(with: URL(string: "wss://stream.binance.com:9443/ws/\(stream)")!)
        liveSocket?.resume()
        receiveLive()
    }

    private func receiveLive() {
        liveSocket?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let err):
                DispatchQueue.main.async {
                    self.errorMessage = err.localizedDescription
                    self.isLoading = false
                }
            case .success(.data(let data)):
                handleLiveData(data)
            case .success(.string(let text)):
                if let data = text.data(using: .utf8) {
                    handleLiveData(data)
                }
            @unknown default:
                break
            }
            self.receiveLive()
        }
    }

    // helper to parse and append a live data point
    private func handleLiveData(_ data: Data) {
        if let msg = try? JSONDecoder().decode(TradeMessage.self, from: data),
           let price = Double(msg.p) {
            let pt = ChartDataPoint(date: Date(timeIntervalSince1970: msg.T / 1000), close: price)
            let current = Date()
            guard current.timeIntervalSince(lastLiveUpdate) >= 1 else { return }
            lastLiveUpdate = current
            // send new point through throttling pipeline instead of direct append
            liveSubject.send(pt)
        }
    }

    func stopLive() {
        liveSocket?.cancel(with: .goingAway, reason: nil)
        liveSocket = nil
    }

    private struct TradeMessage: Decodable {
        let p: String
        let T: TimeInterval
    }

    func fetchData(symbol: String, interval: ChartInterval) {
        if interval == .live {
            self.stopLive()    // tear down any previous stream
            self.startLive(symbol: symbol)
            return
        }
        let pair = symbol.uppercased() + "USDT"
        let urlStr = "https://api.binance.com/api/v3/klines?symbol=\(pair)&interval=\(interval.binanceInterval)&limit=\(interval.binanceLimit)"
        guard let url = URL(string: urlStr) else {
            DispatchQueue.main.async { self.errorMessage = "Invalid URL" }
            return
        }

        DispatchQueue.main.async {
            self.isLoading    = true
            self.errorMessage = nil
            self.dataPoints   = []
        }

        session.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            DispatchQueue.main.async { self.isLoading = false }
            if let err = error {
                return DispatchQueue.main.async { self.errorMessage = err.localizedDescription }
            }
            if let http = response as? HTTPURLResponse, http.statusCode == 451 {
                self.fetchDataFromUS(symbol: symbol, interval: interval)
                return
            }
            guard let data = data else {
                return DispatchQueue.main.async { self.errorMessage = "No data" }
            }
            self.parse(data: data)
        }.resume()
    }

    private func parse(data: Data) {
        do {
            guard let raw = try JSONSerialization.jsonObject(with: data) as? [[Any]] else {
                return DispatchQueue.main.async { self.errorMessage = "Bad JSON" }
            }
            var pts: [ChartDataPoint] = []
            for entry in raw {
                guard entry.count >= 5,
                      let t = entry[0] as? Double
                else { continue }
                let closeRaw = entry[4]
                let date = Date(timeIntervalSince1970: t / 1000)
                let close: Double? = {
                    if let d = closeRaw as? Double { return d }
                    if let s = closeRaw as? String { return Double(s) }
                    return nil
                }()
                if let c = close {
                    pts.append(.init(date: date, close: c))
                }
            }
            pts.sort { $0.date < $1.date }
            DispatchQueue.main.async { self.dataPoints = pts }
        } catch {
            DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
        }
    }

    /// If Binance.com returns HTTP 451, try Binance.US
    private func fetchDataFromUS(symbol: String, interval: ChartInterval) {
        let pair = symbol.uppercased() + "USDT"
        let urlStr = "https://api.binance.us/api/v3/klines?symbol=\(pair)&interval=\(interval.binanceInterval)&limit=\(interval.binanceLimit)"
        guard let url = URL(string: urlStr) else {
            DispatchQueue.main.async { self.errorMessage = "Invalid US URL" }
            return
        }
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            self.dataPoints = []
        }
        session.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async { self.isLoading = false }
            if let err = error {
                return DispatchQueue.main.async { self.errorMessage = err.localizedDescription }
            }
            guard let data = data else {
                return DispatchQueue.main.async { self.errorMessage = "No data from US" }
            }
            self.parse(data: data)
        }.resume()
    }
}

// MARK: – View
struct CryptoChartView: View {
    let symbol  : String
    let interval: ChartInterval
    let height  : CGFloat

    @StateObject private var vm             = CryptoChartViewModel()
    @State private var showCrosshair        = false
    @State private var crosshairDataPoint   : ChartDataPoint? = nil
    @State private var now: Date = Date()

    var body: some View {
        ZStack {
            if interval == .live {
                if vm.dataPoints.isEmpty {
                    ProgressView("Loading…")
                } else {
                    chartContent
                        .frame(height: height)
                }
            } else {
                if vm.isLoading {
                    ProgressView("Loading…")
                } else if let err = vm.errorMessage {
                    errorView(err)
                } else if vm.dataPoints.isEmpty {
                    Text("No data").foregroundColor(.gray)
                } else {
                    chartContent
                        .frame(height: height)
                }
            }
        }
        .onAppear {
            vm.errorMessage = nil
            vm.dataPoints.removeAll()
            if interval == .live {
                vm.startLive(symbol: symbol)
            } else {
                vm.fetchData(symbol: symbol, interval: interval)
            }
        }
        .onChange(of: symbol) { newSymbol in
            vm.errorMessage = nil
            vm.dataPoints.removeAll()
            vm.stopLive()
            if interval == .live {
                vm.startLive(symbol: newSymbol)
            } else {
                vm.fetchData(symbol: newSymbol, interval: interval)
            }
        }
        .onChange(of: interval) { newInterval in
            vm.errorMessage = nil
            vm.dataPoints.removeAll()
            vm.stopLive()
            if newInterval == .live {
                // Load an initial minute's worth of historical data before streaming
                vm.fetchData(symbol: symbol, interval: .oneMin)
                vm.startLive(symbol: symbol)
            } else {
                vm.fetchData(symbol: symbol, interval: newInterval)
            }
        }
        .onDisappear {
            vm.stopLive()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            self.now = date
        }
    }

    private var chartContent: some View {
        Chart {
            ForEach(vm.dataPoints) { pt in
                LineMark(x: .value("Time", pt.date),
                         y: .value("Price", pt.close))
                    .interpolationMethod(.cardinal)
                    .foregroundStyle(.yellow)

                // only draw gradient fill on historical intervals
                if interval != .live {
                    AreaMark(x: .value("Time", pt.date),
                             yStart: .value("Price", yDomain.lowerBound),
                             yEnd: .value("Price", pt.close))
                        .foregroundStyle(
                            LinearGradient(gradient: Gradient(colors: [
                                .yellow.opacity(0.3),
                                .yellow.opacity(0.15),
                                .yellow.opacity(0.05),
                                .clear
                            ]), startPoint: .top, endPoint: .bottom)
                        )
                }
            }

            if showCrosshair, let cp = crosshairDataPoint {
                // Vertical crosshair line
                RuleMark(x: .value("Time", cp.date))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(.white.opacity(0.7))
                // Horizontal crosshair line
                RuleMark(y: .value("Price", cp.close))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(.white.opacity(0.7))
                PointMark(x: .value("Time", cp.date),
                          y: .value("Price", cp.close))
                    .symbolSize(80)
                    .foregroundStyle(.white)
                    .annotation(position: .top) {
                        VStack(spacing: 4) {
                            crosshairDate(cp.date)
                            Text(formatPrice(cp.close))
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        .padding(6)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(6)
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .chartYScale(domain: yDomain)
        .chartXScale(domain: xDomain)
        .chartXScale(range: 0.05...0.95)
        .chartPlotStyle { plotArea in
            plotArea.background(Color.black.opacity(0.05))
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: xAxisCount)) { value in
                AxisGridLine().foregroundStyle(.white.opacity(0.2))
                AxisValueLabel() {
                    if let dateValue = value.as(Date.self) {
                        Text(formatAxisDate(dateValue))
                            .font(.footnote)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
                AxisGridLine().foregroundStyle(.white.opacity(0.2))
                AxisValueLabel()
                    .font(.footnote)
                    .foregroundStyle(.white)
            }
        }
        // Disable implicit animation for live data updates
        .animation(nil, value: vm.dataPoints)
        // only enable crosshair dragging on non-live intervals
        .if(interval != .live) { view in
            view.chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(Color.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    showCrosshair = true
                                    let xPos = gesture.location.x - geo[proxy.plotAreaFrame].origin.x
                                    if let date: Date = proxy.value(atX: xPos),
                                       let nearest = findClosest(to: date) {
                                        crosshairDataPoint = nearest
                                    }
                                }
                                .onEnded { _ in showCrosshair = false }
                        )
                }
            }
        }
        // subtle fade at bottom edge
        .overlay(
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.5)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 40)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .allowsHitTesting(false)
        )
    }

    // MARK: – Helpers
    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 8) {
            Text("Error loading chart").foregroundColor(.red)
            Text(msg).font(.caption).foregroundColor(.gray).multilineTextAlignment(.center)
            Button("Retry") { vm.fetchData(symbol: symbol, interval: interval) }
                .padding(6).background(Color.yellow).cornerRadius(8).foregroundColor(.black)
        }
        .padding()
    }

    private func crosshairDate(_ d: Date) -> Text {
        if interval.hideCrosshairTime {
            return Text(d, format: .dateTime.month().year())
        }
        switch interval {
        case .oneMin, .fiveMin:
            return Text(d, format: .dateTime.hour().minute())
        case .fifteenMin, .thirtyMin, .oneHour, .fourHour:
            return Text(d, format: .dateTime.hour())
        case .oneDay, .oneWeek:
            return Text(d, format: .dateTime.month().day())
        default:
            return Text(d, format: .dateTime.month().year())
        }
    }

    private var yDomain: ClosedRange<Double> {
        let prices = vm.dataPoints.map(\.close)
        guard let lo = prices.min(), let hi = prices.max() else { return 0...1 }
        let pad = (hi - lo) * 0.03
        return (lo - pad)...(hi + pad)
    }

    private var xDomain: ClosedRange<Date> {
        if interval == .live {
            let now = self.now
            return now.addingTimeInterval(-liveWindow)...now
        }
        guard let first = vm.dataPoints.first?.date,
              let last  = vm.dataPoints.last?.date else {
            let now = Date()
            return now.addingTimeInterval(-86_400)...now
        }
        return first...last
    }

    private var xAxisCount: Int {
        switch interval {
        case .live, .oneMin:
            return 6
        case .fiveMin:
            return 4
        case .fifteenMin, .thirtyMin, .oneHour:
            return 6
        case .fourHour:
            return 5
        case .oneDay:
            return 6
        default:
            return 3
        }
    }

    private func formatAxisDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale   = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current

        switch interval {
        case .live, .oneMin, .fiveMin, .fifteenMin, .thirtyMin:
            df.dateFormat = "h:mm a"
        case .oneHour, .fourHour, .oneDay:
            df.dateFormat = "ha"
        case .oneWeek, .oneMonth, .threeMonth:
            df.dateFormat = "MMM d"
        case .oneYear, .threeYear:
            df.dateFormat = "MMM yyyy"
        case .all:
            df.dateFormat = "yyyy"
        }

        return df.string(from: date)
    }

    private func findClosest(to date: Date) -> ChartDataPoint? {
        vm.dataPoints.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }

    private func formatPrice(_ v: Double) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        if v < 1 {
            fmt.minimumFractionDigits = 2
            fmt.maximumFractionDigits = 8
        } else {
            fmt.minimumFractionDigits = 2
            fmt.maximumFractionDigits = 2
        }
        return "$" + (fmt.string(from: v as NSNumber) ?? "\(v)")
    }
}

// MARK: – View Extension for Conditional Modifier
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
