import SwiftUI
import Combine

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
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @StateObject private var vm = ExtendedFearGreedViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "gauge")
                    .foregroundColor(.yellow)
                Text(LocalizedStringKey("Market Sentiment"))
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer(minLength: 0)
            }

            // Subtitle
            Text(LocalizedStringKey("Real-time Fear & Greed updates"))
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.bottom, 4)

            Divider()
                .background(Color.white.opacity(0.15))

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
                    HStack(alignment: .top) {
                        ImprovedHalfCircleGauge(value: Double(vm.currentValue))
                        .frame(width: 280, height: 140)
                            .layoutPriority(1)
                        
                        Spacer(minLength: 24)
                        
                        VStack(alignment: .trailing, spacing: 6) {
                            timeframeRow("Now", vm.data.first)
                            timeframeRow("Yesterday", vm.yesterdayData)
                            timeframeRow("Last Week", vm.lastWeekData)
                        }
                        .padding(.top, 20)
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
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05))
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
            Text(LocalizedStringKey(label))
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

// MARK: - ImprovedHalfCircleGauge

struct ImprovedHalfCircleGauge: View {
    var value: Double
    var lineWidth: CGFloat = 12
    
    static let segments: [(range: ClosedRange<Double>, color: Color)] = [
        (0...25, .red),
        (25...50, .orange),
        (50...75, .yellow),
        (75...100, .green)
    ]
    
    // Color for current value
    private var currentColor: Color {
        Self.segments.first { $0.range.contains(value) }?.color ?? .white
    }
    
    private var classification: String {
        switch value {
        case 0..<25:  return NSLocalizedString("Extreme Fear", comment: "")
        case 25..<50: return NSLocalizedString("Fear", comment: "")
        case 50..<75: return NSLocalizedString("Neutral", comment: "")
        default:      return NSLocalizedString("Greed", comment: "")
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let radius = min(w, h * 2) / 2 - lineWidth / 2
            let center = CGPoint(x: w / 2, y: h)

            // Compute start and end angles
            let startAngle = 180.0
            let endAngle = 180.0 + (value / 100) * 180.0

            ZStack {
                // 1. Static background segments (full arc for each range)
                ForEach(Self.segments.indices, id: \.self) { index in
                    let segment = Self.segments[index]
                    Path { path in
                        path.addArc(
                            center: center,
                            radius: radius,
                            startAngle: .degrees(startAngle + (segment.range.lowerBound / 100) * 180),
                            endAngle: .degrees(startAngle + (segment.range.upperBound / 100) * 180),
                            clockwise: false
                        )
                    }
                    .stroke(
                        segment.color.opacity(0.1),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                    )
                }

                // 2. Active arc up to current value
                Path { path in
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(startAngle),
                        endAngle: .degrees(endAngle),
                        clockwise: false
                    )
                }
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: Self.segments.map { $0.color }),
                        center: .center,
                        startAngle: .degrees(180),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth * 0.8, lineCap: .round)
                )
                .animation(.interpolatingSpring(stiffness: 100, damping: 10), value: value)

                // Calculate marker position
                let rad = CGFloat(Angle(degrees: endAngle).radians)
                let useOutside = value < 50
                let offsetRadius = radius + (useOutside ? lineWidth : -lineWidth) * 1.2
                let labelPos = CGPoint(
                    x: center.x + cos(rad) * offsetRadius,
                    y: center.y + sin(rad) * offsetRadius
                )

                // 3. Needle pointer
                Path { p in
                    let rad = CGFloat(Angle(degrees: endAngle).radians)
                    let needleLength = radius + lineWidth / 2
                    let tip = CGPoint(
                        x: center.x + cos(rad) * needleLength,
                        y: center.y + sin(rad) * needleLength
                    )
                    p.move(to: center)
                    p.addLine(to: tip)
                }
                .stroke(
                    currentColor,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .animation(.interpolatingSpring(stiffness: 100, damping: 10), value: value)

                // 4. Dynamic label rides outside or inside the arc, embedded in colored marker
                Text("\(Int(value))")
                    .font(.caption2).bold()
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(currentColor)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.8), lineWidth: 2)
                    )
                    .position(labelPos)
                    .zIndex(1)
                    .dynamicTypeSize(.medium ... .accessibility3)

                // 5. Ticks and labels (unchanged)
                ForEach([0.0, 100.0], id: \.self) { mark in
                    TickLineView(mark: mark, center: center, radius: radius, lineWidth: lineWidth)
                }
                ForEach([0.0, 50.0, 100.0], id: \.self) { mark in
                    if !(mark == 50.0 && Int(value) == 50) {
                        TickLabelView(mark: mark, center: center, radius: radius, lineWidth: lineWidth)
                    }
                }
            }
            .drawingGroup()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Market sentiment is \(Int(value)) percent, \(classification)"))
        }
    }
}

struct TickLineView: View {
    let mark: Double
    let center: CGPoint
    let radius: CGFloat
    let lineWidth: CGFloat

    private var rad: CGFloat { CGFloat(Angle(degrees: 180 + (mark/100)*180).radians) }
    private var inner: CGPoint {
        CGPoint(
          x: center.x + cos(rad)*(radius - lineWidth/2 - 4),
          y: center.y + sin(rad)*(radius - lineWidth/2 - 4)
        )
    }
    private var outer: CGPoint {
        CGPoint(
          x: center.x + cos(rad)*(radius + lineWidth/2 + 4),
          y: center.y + sin(rad)*(radius + lineWidth/2 + 4)
        )
    }

    var body: some View {
        Path { p in
            p.move(to: inner)
            p.addLine(to: outer)
        }
        .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .butt))
    }
}

struct TickLabelView: View {
    let mark: Double
    let center: CGPoint
    let radius: CGFloat
    let lineWidth: CGFloat

    private var rad: CGFloat { CGFloat(Angle(degrees: 180 + (mark/100)*180).radians) }
    private var labelRadius: CGFloat { radius + lineWidth + 12 }
    private var pos: CGPoint {
        CGPoint(
          x: center.x + cos(rad)*labelRadius,
          y: center.y + sin(rad)*labelRadius
        )
    }

    var body: some View {
        let dy: CGFloat = mark == 50 ? lineWidth + 12 : 4
        let adjustedPos = CGPoint(x: pos.x, y: pos.y + dy)
        Text("\(Int(mark))")
            .font(.caption2).fontWeight(.bold)
            .foregroundColor(.white)
            .shadow(color: Color.black.opacity(0.6), radius: 1)
            .position(adjustedPos)
    }
}
