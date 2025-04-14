//
// MarketSentimentView.swift
// CSAI1
//
// Created by ChatGPT on 3/27/25
//

import SwiftUI
import Combine

// A custom segmented gauge view that divides the 0–100 scale into distinct sentiment zones.
struct SegmentedGauge: View {
    let value: Int

    // Define your segments with ranges and colors.
    private var segments: [(range: ClosedRange<Int>, color: Color)] {
        return [
            (0...25, .red),
            (26...50, .orange),
            (51...75, .yellow),
            (76...100, .green)
        ]
    }
    
    var body: some View {
        ZStack {
            // Draw the background circle outline.
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                .frame(width: 80, height: 80)
            
            // Draw each segment as an arc.
            ForEach(segments.indices, id: \.self) { index in
                let segment = segments[index]
                let segmentStartFraction = CGFloat(segment.range.lowerBound) / 100
                let segmentEndFraction = CGFloat(segment.range.upperBound) / 100
                let currentFraction = CGFloat(min(value, 100)) / 100
                // How much of this segment should be filled:
                let fillFraction = min(max(currentFraction - segmentStartFraction, 0), segmentEndFraction - segmentStartFraction) / (segmentEndFraction - segmentStartFraction)
                if fillFraction > 0 {
                    Circle()
                        .trim(from: segmentStartFraction, to: segmentStartFraction + fillFraction * (segmentEndFraction - segmentStartFraction))
                        .stroke(segment.color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: value)
                }
            }
            
            // Display the numeric value at the center.
            Text("\(value)")
                .font(.title2)
                .bold()
                .foregroundColor(.white)
        }
    }
}

// The main MarketSentimentView.
struct MarketSentimentView: View {
    @StateObject private var viewModel = ExtendedFearGreedViewModel()
    @State private var showDetails = false
    
    // A simple computed property for AI insight based on the current value.
    private var aiInsight: String {
        switch viewModel.currentValue {
        case 0..<20:
            return "Market is extremely fearful. Bargains may be found—but caution is key."
        case 20..<40:
            return "Investors feel cautious. Lower highs may signal a buying opportunity."
        case 40..<60:
            return "Neutral sentiment suggests stability. Markets are consolidating."
        case 60..<80:
            return "Optimism is rising. Some momentum is building."
        default:
            return "Market is extremely greedy. Consider a potential pullback."
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Market Sentiment")
                .font(.headline)
                .foregroundColor(.white)
            
            if viewModel.isLoading {
                ProgressView("Loading Fear & Greed...")
                    .foregroundColor(.white)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                    Button("Retry") {
                        viewModel.fetchData()
                    }
                    .font(.caption)
                    .padding(6)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                }
            } else if viewModel.data.isEmpty {
                VStack(spacing: 8) {
                    Text("No sentiment data available.")
                        .foregroundColor(.white)
                        .font(.caption)
                    Button("Retry") {
                        viewModel.fetchData()
                    }
                    .font(.caption)
                    .padding(6)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                }
            } else {
                // Use our custom segmented gauge.
                HStack(alignment: .center, spacing: 16) {
                    SegmentedGauge(value: viewModel.currentValue)
                        .onTapGesture { showDetails.toggle() }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Color-code the "Now" line based on classification.
                        Text("Now: \(viewModel.currentValue) (\(viewModel.currentLabel))")
                            .font(.subheadline)
                            .foregroundColor(colorForClassification(viewModel.currentLabel))
                        
                        if let yData = viewModel.yesterdayData {
                            Text("Yesterday: \(yData.value) (\(yData.valueClassification))")
                                .font(.caption)
                                .foregroundColor(colorForClassification(yData.valueClassification))
                        }
                        if let lwData = viewModel.lastWeekData {
                            Text("Last Week: \(lwData.value) (\(lwData.valueClassification))")
                                .font(.caption)
                                .foregroundColor(colorForClassification(lwData.valueClassification))
                        }
                        
                        Text("Data from alternative.me")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.3)))
                .onTapGesture { showDetails.toggle() }
                
                // Display AI Insight below gauge.
                Text("AI Insight: \(aiInsight)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 6)
                    .transition(.opacity)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
        .onAppear { viewModel.fetchData() }
        .sheet(isPresented: $showDetails) {
            MarketSentimentDetailView(viewModel: viewModel)
        }
    }
    
    // Helper to map classification string to a Color.
    private func colorForClassification(_ classification: String) -> Color {
        switch classification.lowercased() {
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
}

struct MarketSentimentDetailView: View {
    @ObservedObject var viewModel: ExtendedFearGreedViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                if viewModel.data.isEmpty {
                    Text("No historical data available.")
                        .foregroundColor(.white)
                } else {
                    ForEach(Array(viewModel.data.enumerated()), id: \.offset) { index, data in
                        HStack {
                            Text(index == 0 ? "Now" : (index == 1 ? "Yesterday" : "Day \(index+1)"))
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(data.value) (\(data.valueClassification))")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Sentiment History")
            .toolbar {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
}

struct MarketSentimentView_Previews: PreviewProvider {
    static var previews: some View {
        MarketSentimentView()
            .preferredColorScheme(.dark)
            .background(Color.black)
    }
}
