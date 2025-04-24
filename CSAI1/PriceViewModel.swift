//
//  BinancePriceResponse.swift
//  CSAI1
//
//  Created by DM on 4/23/25.
//


//
//  PriceViewModel.swift
//  CSAI1
//
//  Created by DM on 4/22/25.
//

import Foundation
import Combine

/// Fallback model for Binance REST response
struct BinancePriceResponse: Decodable {
    let symbol: String
    let price: String
}

@MainActor
class PriceViewModel: ObservableObject {
    @Published var currentPrice: Double?
    @Published var symbol: String
    private var cancellables = Set<AnyCancellable>()
    private let service = CoinbaseService()
    
    /// Fallback: fetch spot price from Binance REST if Coinbase fails.
    private func fetchBinancePrice(for symbol: String) async -> Double? {
        let pair = symbol.uppercased() + "USDT"
        guard let url = URL(string: "https://api.binance.com/api/v3/ticker/price?symbol=\(pair)") else {
            print("PriceViewModel: invalid URL for \(pair)")
            return nil
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(BinancePriceResponse.self, from: data)
            return Double(decoded.price)
        } catch {
            print("PriceViewModel: Binance fetch error for \(pair): \(error)")
            return nil
        }
    }

    /// Map common symbols to CoinGecko IDs
    private func coingeckoID(for symbol: String) -> String {
        switch symbol.uppercased() {
        case "BTC": return "bitcoin"
        case "ETH": return "ethereum"
        case "BNB": return "binancecoin"
        case "SOL": return "solana"
        case "ADA": return "cardano"
        case "XRP": return "ripple"
        case "DOGE": return "dogecoin"
        // add more as needed
        default: return symbol.lowercased()
        }
    }

    /// Fallback: fetch spot price from CoinGecko if Binance fails or is blocked
    private func fetchCoingeckoPrice(for symbol: String) async -> Double? {
        let id = coingeckoID(for: symbol)
        guard let url = URL(string: "https://api.coingecko.com/api/v3/simple/price?ids=\(id)&vs_currencies=usd") else {
            print("PriceViewModel: invalid CoinGecko URL for \(id)")
            return nil
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let entry = json[id] as? [String: Any],
               let price = entry["usd"] as? Double {
                return price
            }
        } catch {
            print("PriceViewModel: CoinGecko fetch error for \(symbol):", error)
        }
        return nil
    }
    
    init(symbol: String) {
        self.symbol = symbol
        // Kick off immediate and recurring fetches for the symbol
        updateSymbol(symbol)
    }
    
    /// Change the symbol being tracked and restart the polling timer, Binance REST with CoinGecko fallback
    func updateSymbol(_ newSymbol: String) {
        // Cancel any existing polling subscriptions
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

        // Immediate fetch: try Coinbase, then Binance, then CoinGecko
        Task {
            if let price = await self.service.fetchSpotPrice(coin: newSymbol) {
                self.currentPrice = price
                print("PriceViewModel: fetched initial Coinbase price \(price) for \(newSymbol)")
            } else if let price = await fetchBinancePrice(for: newSymbol) {
                self.currentPrice = price
                print("PriceViewModel: fetched initial Binance price \(price) for \(newSymbol)")
            } else if let price = await fetchCoingeckoPrice(for: newSymbol) {
                self.currentPrice = price
                print("PriceViewModel: fetched initial CoinGecko price \(price) for \(newSymbol)")
            } else {
                print("PriceViewModel: all initial fetches failed for \(newSymbol)")
            }
        }

        let updatePublisher = Publishers.Merge(
            Just(Date()),
            Timer.publish(every: 5, on: .main, in: .common).autoconnect()
        )

        updatePublisher
            .sink { [weak self] _ in
                Task {
                    guard let self = self else { return }
                    if let price = await self.service.fetchSpotPrice(coin: newSymbol) {
                        self.currentPrice = price
                        print("PriceViewModel: polled Coinbase price \(price) for \(newSymbol)")
                    } else if let price = await self.fetchBinancePrice(for: newSymbol) {
                        self.currentPrice = price
                        print("PriceViewModel: polled Binance price \(price) for \(newSymbol)")
                    } else if let price = await self.fetchCoingeckoPrice(for: newSymbol) {
                        self.currentPrice = price
                        print("PriceViewModel: polled CoinGecko price \(price) for \(newSymbol)")
                    } else {
                        print("PriceViewModel: all polled fetches failed for \(newSymbol)")
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    /// Begin polling for the current symbol
    func startPolling() {
        updateSymbol(symbol)
    }

    /// Stop any active polling timers
    func stopPolling() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
