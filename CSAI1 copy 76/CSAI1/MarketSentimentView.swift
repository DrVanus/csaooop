import SwiftUI

// MARK: - DataUnavailableView

struct DataUnavailableView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(message)
                .font(.caption)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Button(action: onRetry) {
                Text("Retry")
                    .font(.caption2)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.yellow)
                    .cornerRadius(6)
                    .foregroundColor(.black)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - MarketSentimentView

struct MarketSentimentView: View {
    @StateObject private var vm = ExtendedFearGreedViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "speedometer")
                    .foregroundColor(.yellow)
                Text("Market Sentiment")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer(minLength: 0)
            }

            // Subtitle
            Text("Real‑time Fear & Greed updates")
                .font(.footnote)
                .foregroundColor(.gray)

            Divider()
                .background(Color.white.opacity(0.15))
                .padding(.bottom, 4)

            // Main content
            Group {
                if vm.isLoading {
                    ProgressView()
                        .tint(.yellow)
                        .frame(maxWidth: .infinity)
                } else if let err = vm.errorMessage {
                    DataUnavailableView(message: err, onRetry: vm.fetchData)
                } else if vm.data.isEmpty {
                    DataUnavailableView(message: "No data available.", onRetry: vm.fetchData)
                } else {
                    HStack(alignment: .center, spacing: 16) {
                        HalfCircleGauge(fraction: Double(vm.currentValue) / 100.0)
                            .frame(width: 140, height: 80)
                            .layoutPriority(1)

                        VStack(alignment: .leading, spacing: 4) {
                            timeframeRow("Now", vm.data.first)
                            timeframeRow("Yesterday", vm.yesterdayData)
                            timeframeRow("Last Week", vm.lastWeekData)
                        }
                    }
                }
            }

            // AI Observations
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Observations")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.yellow)
                Text(aiInsight(for: CGFloat(vm.currentValue)))
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
        .onAppear { vm.fetchData() }
        .onReceive(
            Timer.publish(every: 120, on: .main, in: .common).autoconnect()
        ) { _ in vm.fetchData() }
    }

    // MARK: - Helpers

    private func timeframeRow(_ label: String, _ d: FearGreedData?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
            if let x = d {
                Text("\(x.value) \(x.valueClassification.capitalized)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color(for: x.valueClassification))
            } else {
                Text("—")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }

    private func color(for cls: String) -> Color {
        switch cls.lowercased() {
        case "extreme fear":  return .red
        case "fear":          return .orange
        case "neutral":       return .yellow
        case "greed":         return .green
        case "extreme greed": return .mint
        default:              return .gray
        }
    }

    private func aiInsight(for v: CGFloat) -> String {
        switch v {
        case 0..<25:  return "Extreme Fear—market is fragile."
        case 25..<50: return "Fear—selective buying might be possible."
        case 50..<75: return "Neutral—monitor momentum."
        default:      return "Greed—potential profit‑taking."
        }
    }
}

// MARK: - HalfCircleGauge

struct HalfCircleGauge: View {
    /// fraction from 0.0 to 1.0
    var fraction: Double
    var lineWidth: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            let diameter = min(geo.size.width, geo.size.height * 2)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height)
            let radius = diameter / 2 - lineWidth / 2

            ZStack {
                // Background arc
                Path { path in
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(180),
                        endAngle: .degrees(360),
                        clockwise: false
                    )
                }
                .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                // Foreground arc
                Path { path in
                    let endAngle = 180 + fraction * 180
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(180),
                        endAngle: .degrees(endAngle),
                        clockwise: false
                    )
                }
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: .red, location: 0.0),
                            .init(color: .orange, location: 0.25),
                            .init(color: .yellow, location: 0.5),
                            .init(color: .green, location: 0.75)
                        ]),
                        center: .center,
                        startAngle: .degrees(180),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

                // Center label
                Text("\(Int(fraction * 100))")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.75)
            }
        }
    }
}
