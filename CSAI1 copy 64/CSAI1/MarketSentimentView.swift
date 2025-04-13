//
// MarketSentimentView.swift
// CSAI1
//
// Created by ChatGPT on 3/27/25
//

import SwiftUI

struct MarketSentimentView: View {
    @StateObject private var viewModel = FearGreedViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            Text("Market Sentiment")
                .font(.headline)
                .foregroundColor(.white)
            
            // Handle different states
            if viewModel.isLoading {
                ProgressView("Loading Fear & Greed...")
                    .foregroundColor(.white)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                    Button("Retry") {
                        viewModel.fetchIndex()
                    }
                    .font(.caption)
                    .padding(6)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                }
            } else {
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        // Background circle gauge
                        Circle()
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 10)
                            .frame(width: 60, height: 60)
                        
                        // Foreground circle trimmed to represent the index
                        Circle()
                            .trim(from: 0, to: CGFloat(viewModel.value) / 100)
                            .stroke(Color.yellow, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.5), value: viewModel.value)
                        
                        // Numerical display in the center
                        Text("\(viewModel.value)")
                            .font(.subheadline).bold()
                            .foregroundColor(.yellow)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fear & Greed Index: \(viewModel.value) (\(viewModel.label))")
                            .font(.subheadline)
                            .foregroundColor(.yellow)
                        Text("Data from alternative.me")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
        .onAppear {
            viewModel.fetchIndex()
        }
    }
}

struct MarketSentimentView_Previews: PreviewProvider {
    static var previews: some View {
        MarketSentimentView()
            .preferredColorScheme(.dark)
            .padding()
            .background(Color.black)
    }
}
