//
// MarketSentimentView.swift
// CSAI1
//
// Final refined approach:
//   • Card-style tinted background (light gray tint) behind all content.
//   • No clipping of the header ("Market Sentiment") – full visibility ensured.
//   • Gauge sized at ~320×200 with thick arcs (lineWidth = 12)
//   • Rectangular needle rotates from center (0–100 mapped to 0–180°)
//   • Numeric readout inside the gauge offset slightly upward.
//   • Right-side single-column timeframe block (fixed width = 80) for “Now,” “Yesterday,” and “Last Week”.
//   • AI Observations text placed immediately below with minimal spacing.
// (C) 2025 by ChatGPT
//

import SwiftUI
import Combine

// MARK: - DataUnavailableView
struct DataUnavailableView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Text(message)
                .foregroundColor(.white)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            Button("Retry") {
                onRetry()
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.yellow)
            .cornerRadius(6)
            .foregroundColor(.black)
        }
        .padding(6)
    }
}

// MARK: - LargeNeedleGaugeView
/// A half–circle gauge mapping values [0...100] to angles [0...180]° with thick, colored arcs,
/// a rectangular needle pivoting at the center, and a numeric label offset upward.
struct LargeNeedleGaugeView: View {
    let gaugeValue: CGFloat
    
    // Map gaugeValue (0–100) to angle (0–180°)
    private var needleAngle: Double {
        Double(gaugeValue) * 1.8
    }
    
    // Offset for the numeric readout to reduce extra vertical space below the gauge
    private let numericOffsetY: CGFloat = -20
    
    var body: some View {
        GeometryReader { geo in
            let size   = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size/2, y: size/2)
            let radius = size * 0.45
            
            ZStack {
                // Colored arc segments
                GaugeArcSegment(startValue: 0,   endValue: 25,  color: .red,    lineWidth: 12)
                GaugeArcSegment(startValue: 25,  endValue: 50,  color: .orange, lineWidth: 12)
                GaugeArcSegment(startValue: 50,  endValue: 75,  color: .yellow, lineWidth: 12)
                GaugeArcSegment(startValue: 75,  endValue: 100, color: .green,  lineWidth: 12)
                
                // Tick labels positioned along the arc (0,50,100)
                ForEach([0, 50, 100], id: \.self) { tick in
                    let angle    = Angle(degrees: 180.0 * Double(tick) / 100.0)
                    let labelPos = pointOnArc(center: center, radius: radius * 1.1, angle: angle)
                    Text("\(tick)")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .position(labelPos)
                }
                
                // Rectangular needle rotates based on gaugeValue
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 3, height: radius * 0.9)
                    .rotationEffect(.degrees(needleAngle), anchor: .center)
                    .position(x: center.x, y: center.y)
                
                // Numeric readout inside the gauge, offset upward
                Text("\(Int(gaugeValue))")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .offset(y: numericOffsetY)
                    .position(x: center.x, y: center.y)
            }
            .frame(width: size, height: size)
        }
    }
    
    // Helper: calculate position for tick labels along the arc
    private func pointOnArc(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        let rad = CGFloat(angle.radians)
        let x   = center.x + radius * cos(rad - .pi)
        let y   = center.y + radius * sin(rad - .pi)
        return CGPoint(x: x, y: y)
    }
}

// MARK: - GaugeArcSegment & ArcShape
struct GaugeArcSegment: View {
    let startValue: CGFloat
    let endValue: CGFloat
    let color: Color
    let lineWidth: CGFloat
    
    var body: some View {
        ArcShape(startAngle: angleFor(startValue),
                 endAngle:   angleFor(endValue))
            .stroke(color, lineWidth: lineWidth)
    }
    
    private func angleFor(_ value: CGFloat) -> Angle {
        .degrees(Double(value) * 1.8)
    }
}

struct ArcShape: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.45
        var path = Path()
        path.addArc(center: center,
                    radius: radius,
                    startAngle: startAngle + .degrees(180),
                    endAngle:   endAngle   + .degrees(180),
                    clockwise: false)
        return path
    }
}

// MARK: - MarketSentimentView
struct MarketSentimentView: View {
    @StateObject private var viewModel = ExtendedFearGreedViewModel()
    @State private var gaugeValue: CGFloat = 0
    
    // Timeframe data (always displayed as static text)
    private var nowItem: FearGreedData? {
        viewModel.data.first
    }
    private var yesterdayItem: FearGreedData? {
        viewModel.data.count > 1 ? viewModel.data[1] : nil
    }
    private var lastWeekItem: FearGreedData? {
        viewModel.data.count > 2 ? viewModel.data[2] : nil
    }
    
    // AI Observations based on the gauge value
    private var aiInsight: String {
        switch gaugeValue {
        case 0..<25:   return "Extreme Fear—market is fragile."
        case 25..<50:  return "Fear—selective buying might be possible."
        case 50..<75:  return "Neutral—monitor momentum."
        default:       return "Greed—potential profit-taking."
        }
    }
    
    var body: some View {
        ZStack {
            // Tinted card background matching the home page style
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemGray6).opacity(0.15))
                .edgesIgnoringSafeArea(.all)
            
            // Content inside the card
            VStack(alignment: .leading, spacing: 6) {
                // Title & subtitle – make sure text is fully visible
                VStack(alignment: .leading, spacing: 2) {
                    Text("Market Sentiment")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Real-time Fear & Greed updates")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                
                // Check for loading/error/empty states
                if viewModel.isLoading {
                    loadingPlaceholder
                } else if let error = viewModel.errorMessage {
                    DataUnavailableView(message: error) {
                        viewModel.fetchData()
                    }
                } else if viewModel.data.isEmpty {
                    DataUnavailableView(message: "No sentiment data available.") {
                        viewModel.fetchData()
                    }
                } else {
                    // Main content area: gauge on the left, timeframe rows on the right
                    HStack(alignment: .top, spacing: 8) {
                        // The gauge with a fixed size
                        LargeNeedleGaugeView(gaugeValue: gaugeValue)
                            .frame(width: 320, height: 200)
                        
                        // Timeframe static values in a fixed-width column
                        VStack(alignment: .leading, spacing: 4) {
                            timeframeRow("Now", nowItem)
                            timeframeRow("Yesterday", yesterdayItem)
                            timeframeRow("Last Week", lastWeekItem)
                        }
                        .frame(width: 80, alignment: .leading)
                    }
                    
                    // AI Observations area – with minimal vertical gap
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Observations")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.yellow)
                        Text(aiInsight)
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
            }
            .padding(12)
        }
        .onAppear {
            viewModel.fetchData()
        }
        // Update gauge when data changes
        .onReceive(viewModel.$data) { newData in
            withAnimation(.easeInOut(duration: 1.0)) {
                if let first = newData.first, let valInt = Int(first.value) {
                    gaugeValue = CGFloat(max(min(valInt, 100), 0))
                } else {
                    gaugeValue = 0
                }
            }
        }
        // Auto-refresh every 2 minutes
        .onReceive(Timer.publish(every: 120, on: .main, in: .common).autoconnect()) { _ in
            viewModel.fetchData()
        }
    }
    
    // MARK: - Timeframe Row helper
    private func timeframeRow(_ label: String, _ data: FearGreedData?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
            if let d = data {
                Text("\(d.value) \(d.valueClassification)")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForClassification(d.valueClassification))
            } else {
                Text("—")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
    }
    
    // Helper: get color based on classification text
    private func colorForClassification(_ c: String) -> Color {
        switch c.lowercased() {
        case "extreme fear":
            return .red
        case "fear":
            return .orange
        case "neutral":
            return .yellow
        case "greed":
            return .green
        case "extreme greed":
            return .mint
        default:
            return .gray
        }
    }
    
    // MARK: - Loading Placeholder
    private var loadingPlaceholder: some View {
        VStack(spacing: 6) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                .scaleEffect(0.8)
            Text("Loading Sentiment...")
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
    }
}

// MARK: - Preview
struct MarketSentimentView_Previews: PreviewProvider {
    static var previews: some View {
        MarketSentimentView()
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
