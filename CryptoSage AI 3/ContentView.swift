//
//  ContentView.swift
//  CryptoSage AI 3
//
//  Created by DM on 2/21/25.
//

import SwiftUI
import WebKit
import Foundation
import Speech
import AVFoundation

// MARK: - Extend UIApplication for Keyboard Dismiss
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder),
                   to: nil, from: nil, for: nil)
    }
}

// MARK: - iOS 16+ Entry
@available(iOS 16.0, *)
@main
struct CryptoSageAIApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentManagerView()
                .environmentObject(appState)
                // Keep dark mode by default
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
    }
}

// MARK: - Shared AppState
@available(iOS 16.0, *)
class AppState: ObservableObject {
    @Published var selectedTab: CustomTab = .home
    @Published var isDarkMode: Bool = true
}

// MARK: - Tabs
@available(iOS 16.0, *)
enum CustomTab: String {
    case home      = "Home"
    case market    = "Market"
    case trade     = "Trade"
    case portfolio = "Portfolio"
    case ai        = "AI"
}

// MARK: - Main Content
@available(iOS 16.0, *)
struct ContentManagerView: View {
    @EnvironmentObject var appState: AppState
    
    @StateObject private var homeVM   = HomeViewModel()
    @StateObject private var marketVM = MarketViewModel()
    @StateObject private var tradeVM  = TradeViewModel()
    
    var body: some View {
        ZStack {
            switch appState.selectedTab {
            case .home:
                HomeView(viewModel: homeVM, marketVM: marketVM, tradeVM: tradeVM) {
                    homeVM.showSettings.toggle()
                }
                .sheet(isPresented: $homeVM.showSettings) {
                    NavigationView {
                        SettingsView()
                            .environmentObject(homeVM)
                            .environmentObject(appState)
                    }
                    .presentationDetents([.medium, .large])
                }
                
            case .market:
                MarketView(marketVM: marketVM, homeVM: homeVM, tradeVM: tradeVM)
                
            case .trade:
                TradeView(tradeVM: tradeVM)
                
            case .portfolio:
                PortfolioView()
                
            case .ai:
                AITabView()
            }
            
            // Bottom tab bar
            VStack {
                Spacer()
                CustomTabBar()
            }
        }
        .gesture(
            DragGesture().onChanged { _ in
                UIApplication.shared.endEditing()
            }
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            homeVM.refreshWatchlistData()
            homeVM.fetchNews()
            homeVM.fetchTrending()
            marketVM.fetchMarketCoins()
            homeVM.loadUserWallets()
        }
    }
}

// MARK: - Custom Tab Bar
@available(iOS 16.0, *)
struct CustomTabBar: View {
    @EnvironmentObject var appState: AppState
    let tabs: [CustomTab] = [.home, .market, .trade, .portfolio, .ai]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 16)
        .background(Color.black.opacity(0.9))
    }
    
    @ViewBuilder
    func tabButton(_ tab: CustomTab) -> some View {
        Button(action: { appState.selectedTab = tab }) {
            VStack(spacing: 2) {
                switch tab {
                case .home:
                    Image(systemName: "house.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text(tab.rawValue).font(.caption2)
                    
                case .market:
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 18, weight: .semibold))
                    Text(tab.rawValue).font(.caption2)
                    
                case .trade:
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text(tab.rawValue).font(.caption2)
                    
                case .portfolio:
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text(tab.rawValue).font(.caption2)
                    
                case .ai:
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                    Text(tab.rawValue).font(.caption2)
                }
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(appState.selectedTab == tab ? .blue : .gray)
        }
    }
}

// MARK: - HOME VIEW
@available(iOS 16.0, *)
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var marketVM: MarketViewModel
    let tradeVM: TradeViewModel?
    let onOpenSettings: () -> Void
    
    @State private var showNewsWeb = false
    @State private var newsURL: URL? = nil
    
    @State private var trendingDetailCoin: CoinGeckoCoin? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        heroSection
                        portfolioSummaryCard
                        trendingSection
                        
                        watchlistSection
                        topGainersSection
                        newsSection
                        
                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .refreshable {
                    viewModel.refreshWatchlistData()
                    viewModel.fetchNews()
                    viewModel.fetchTrending()
                }
            }
            .navigationBarTitle("Home", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onOpenSettings()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showNewsWeb) {
                if let url = newsURL {
                    NewsWebView(url: url)
                } else {
                    Text("No URL to load.")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black)
                }
            }
            .sheet(item: $trendingDetailCoin) { coin in
                CoinDetailView(coin: coin, homeVM: viewModel, tradeVM: tradeVM)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    var heroSection: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.black, .gray]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(10)
            
            VStack(spacing: 4) {
                Text("Welcome to CryptoSage AI")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("Your Next-Gen Crypto Tools")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.vertical, 16)
        }
        .frame(height: 80)
    }
    
    var portfolioSummaryCard: some View {
        let totalValue: Double = 19290.0
        let dailyChangePercent: Double = 2.83
        let sign = dailyChangePercent >= 0 ? "+" : ""
        
        return CardView(cornerRadius: 6, paddingAmount: 8) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Portfolio Summary")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Total Value: $\(totalValue, specifier: "%.2f")")
                    .foregroundColor(.white)
                
                Text("24h Change: \(sign)\(dailyChangePercent, specifier: "%.2f")%")
                    .foregroundColor(dailyChangePercent >= 0 ? .green : .red)
                
                Button {
                    appState.selectedTab = .portfolio
                } label: {
                    Text("View Full Portfolio")
                        .font(.subheadline)
                        .padding(6)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    var trendingSection: some View {
        Group {
            if !viewModel.trendingCoins.isEmpty {
                CardView(cornerRadius: 6, paddingAmount: 4) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Trending")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.trendingCoins) { tcoin in
                                    Button {
                                        viewModel.fetchCoinByID(tcoin.id) { fetchedCoin in
                                            DispatchQueue.main.async {
                                                if let realCoin = fetchedCoin {
                                                    self.trendingDetailCoin = realCoin
                                                }
                                            }
                                        }
                                    } label: {
                                        TrendingCard(item: MarketItem(
                                            symbol: tcoin.symbol.uppercased(),
                                            price: tcoin.price,
                                            change: tcoin.priceChange24h
                                        ))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    var watchlistSection: some View {
        CardView(cornerRadius: 6, paddingAmount: 4) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Watchlist")
                    .font(.headline)
                    .foregroundColor(.white)
                Divider().background(Color.gray)
                
                if viewModel.isLoadingCoins {
                    Text("Loading coin prices...")
                        .foregroundColor(.gray)
                } else {
                    if viewModel.watchlistCoins.isEmpty {
                        Text("No watchlist coins found.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(viewModel.watchlistCoins.indices, id: \.self) { index in
                            let coin = viewModel.watchlistCoins[index]
                            NavigationLink {
                                CoinDetailView(coin: coin, homeVM: viewModel, tradeVM: tradeVM)
                            } label: {
                                VStack {
                                    WatchlistRow(item: MarketItem(
                                        symbol: coin.symbol.uppercased(),
                                        price: coin.currentPrice ?? 0,
                                        change: coin.priceChangePercentage24h ?? 0
                                    ))
                                    Divider().background(Color.gray.opacity(0.4))
                                }
                                .padding(.vertical, 1)
                                .contentShape(Rectangle())
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    if let coinID = coin.coinGeckoID as String? {
                                        viewModel.removeFromWatchlist(coinID: coinID)
                                        viewModel.refreshWatchlistData()
                                    }
                                } label: {
                                    Text("Remove from Watchlist")
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    var topGainersSection: some View {
        CardView(cornerRadius: 6, paddingAmount: 4) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Top Gainers")
                    .font(.headline)
                    .foregroundColor(.white)
                Divider().background(Color.gray)
                
                let topGainers = marketVM.marketCoins
                    .sorted { ($0.priceChangePercentage24h ?? 0) > ($1.priceChangePercentage24h ?? 0) }
                    .prefix(3)
                
                if topGainers.isEmpty {
                    Text("No data yet.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(topGainers) { coin in
                        let change = coin.priceChangePercentage24h ?? 0
                        VStack {
                            WatchlistRow(item: MarketItem(
                                symbol: coin.symbol.uppercased(),
                                price: coin.currentPrice ?? 0,
                                change: change
                            ))
                            Divider().background(Color.gray.opacity(0.4))
                        }
                        .padding(.vertical, 1)
                    }
                }
            }
        }
    }
    
    var newsSection: some View {
        CardView(cornerRadius: 6, paddingAmount: 4) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Latest Crypto News (In-App)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if viewModel.isLoadingNews {
                    Text("Loading news...")
                        .foregroundColor(.gray)
                } else {
                    if viewModel.news.isEmpty {
                        Text("No news found.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(viewModel.news) { news in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(news.title)
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                                
                                HStack {
                                    Text(news.source)
                                        .foregroundColor(.gray)
                                        .font(.footnote)
                                    Spacer()
                                    
                                    if let url = news.url, !url.absoluteString.isEmpty {
                                        Button("Read More") {
                                            self.newsURL = url
                                            self.showNewsWeb = true
                                        }
                                        .foregroundColor(.blue)
                                        .font(.footnote)
                                    } else {
                                        Text("No link available")
                                            .foregroundColor(.gray)
                                            .font(.footnote)
                                    }
                                }
                            }
                            Divider().background(Color.gray.opacity(0.4))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - NEWS WEBVIEW
@available(iOS 16.0, *)
struct NewsWebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - MARKET SORT OPTION
enum MarketSortOption {
    case name, price, change
}

// MARK: - MARKET VIEW
@available(iOS 16.0, *)
struct MarketView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var marketVM: MarketViewModel
    @ObservedObject var homeVM: HomeViewModel
    @ObservedObject var tradeVM: TradeViewModel
    
    @State private var searchText = ""
    @State private var sortOption: MarketSortOption = .name
    @State private var includeSolana = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        Toggle("Include Solana (DexScreener)", isOn: $includeSolana)
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            .foregroundColor(.white)
                        
                        HStack {
                            TextField("Search coins...", text: $searchText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.leading)
                                .padding(.vertical, 6)
                            
                            Spacer()
                            
                            Menu("Sort By") {
                                Button("Name") { sortOption = .name }
                                Button("Price") { sortOption = .price }
                                Button("24h %") { sortOption = .change }
                            }
                            .padding(.trailing, 8)
                            .foregroundColor(.white)
                        }
                        
                        if marketVM.isLoading {
                            Text("Loading market data...")
                                .foregroundColor(.gray)
                                .padding()
                            Spacer()
                        } else {
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Fav")
                                        .foregroundColor(.gray)
                                        .frame(width: 32)
                                    Text("Coin")
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text("Price")
                                        .foregroundColor(.gray)
                                        .frame(width: 70, alignment: .trailing)
                                    Text("24h")
                                        .foregroundColor(.gray)
                                        .frame(width: 50, alignment: .trailing)
                                    Text("Volume")
                                        .foregroundColor(.gray)
                                        .frame(width: 70, alignment: .trailing)
                                    Text("High/Low")
                                        .foregroundColor(.gray)
                                        .frame(width: 80, alignment: .trailing)
                                }
                                .padding(.vertical, 4)
                                .background(Color.black)
                                
                                Divider().background(Color.gray)
                                
                                if sortedCoins.isEmpty {
                                    VStack {
                                        Text("No coins match your search.")
                                            .foregroundColor(.gray)
                                            .padding()
                                    }
                                } else {
                                    ForEach(sortedCoins, id: \.coinGeckoID) { coin in
                                        VStack(spacing: 0) {
                                            HStack {
                                                Image(systemName: homeVM.watchlistIDs.contains(coin.coinGeckoID) ? "star.fill" : "star")
                                                    .foregroundColor(homeVM.watchlistIDs.contains(coin.coinGeckoID) ? .yellow : .gray)
                                                    .frame(width: 32)
                                                    .onTapGesture {
                                                        if homeVM.watchlistIDs.contains(coin.coinGeckoID) {
                                                            homeVM.removeFromWatchlist(coinID: coin.coinGeckoID)
                                                        } else {
                                                            homeVM.addToWatchlist(coinID: coin.coinGeckoID)
                                                        }
                                                        homeVM.refreshWatchlistData()
                                                    }
                                                
                                                NavigationLink {
                                                    CoinDetailView(
                                                        coin: coin,
                                                        homeVM: homeVM,
                                                        tradeVM: tradeVM
                                                    )
                                                    .navigationBarBackButtonHidden(false)
                                                } label: {
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(coin.symbol.uppercased())
                                                            .foregroundColor(.white)
                                                            .fontWeight(.semibold)
                                                        Text(coin.name ?? "")
                                                            .foregroundColor(.gray)
                                                            .font(.caption2)
                                                    }
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                                
                                                Text("$\(coin.currentPrice ?? 0, specifier: "%.2f")")
                                                    .foregroundColor(.white)
                                                    .frame(width: 70, alignment: .trailing)
                                                
                                                let change = coin.priceChangePercentage24h ?? 0
                                                Text("\(change >= 0 ? "+" : "")\(change, specifier: "%.2f")%")
                                                    .foregroundColor(change >= 0 ? .green : .red)
                                                    .frame(width: 50, alignment: .trailing)
                                                
                                                Text("$\(Int(coin.totalVolume ?? 0))")
                                                    .foregroundColor(.white)
                                                    .frame(width: 70, alignment: .trailing)
                                                
                                                let high = coin.high24h ?? 0
                                                let low  = coin.low24h ?? 0
                                                Text("\(String(format: "%.2f", high))/\(String(format: "%.2f", low))")
                                                    .foregroundColor(.white)
                                                    .frame(width: 80, alignment: .trailing)
                                            }
                                            .padding(.vertical, 4)
                                            .background(Color.black)
                                            
                                            Divider().background(Color.gray.opacity(0.4))
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            Spacer().frame(height: 80)
                        }
                    }
                }
                .refreshable {
                    marketVM.fetchMarketCoins()
                }
            }
            .navigationBarTitle("Market", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    var sortedCoins: [CoinGeckoCoin] {
        let filtered = marketVM.marketCoins.filter {
            searchText.isEmpty ||
            $0.symbol.lowercased().contains(searchText.lowercased()) ||
            ($0.name?.lowercased().contains(searchText.lowercased()) ?? false)
        }
        switch sortOption {
        case .name:
            return filtered.sorted { ($0.name ?? "") < ($1.name ?? "") }
        case .price:
            return filtered.sorted { ($0.currentPrice ?? 0) > ($1.currentPrice ?? 0) }
        case .change:
            return filtered.sorted { ($0.priceChangePercentage24h ?? 0) > ($1.priceChangePercentage24h ?? 0) }
        }
    }
}

// MARK: - MARKET VIEWMODEL
class MarketViewModel: ObservableObject {
    @Published var marketCoins: [CoinGeckoCoin] = []
    @Published var isLoading = false
    
    func fetchMarketCoins() {
        isLoading = true
        guard let url = URL(string:
            "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=200&page=1&sparkline=false"
        ) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            if let error = error {
                print("Error fetching market coins: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode([CoinGeckoCoin].self, from: data)
                DispatchQueue.main.async {
                    self.marketCoins = decoded
                }
            } catch {
                print("Error decoding market coins: \(error)")
            }
        }.resume()
    }
}

// MARK: - TRADE TIMEFRAME
enum TradeTimeframe: String {
    case oneHour = "60"
    case oneDay  = "D"
    case oneWeek = "W"
}

// MARK: - COIN DETAIL VIEW
@available(iOS 16.0, *)
struct CoinDetailView: View {
    let coin: CoinGeckoCoin
    @ObservedObject var homeVM: HomeViewModel
    var tradeVM: TradeViewModel? = nil
    
    @EnvironmentObject var appState: AppState
    @State private var timeframe: TradeTimeframe = .oneHour
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                ScrollView {
                    VStack(spacing: 12) {
                        Text("\(coin.name ?? ("Official " + coin.symbol.uppercased())) Details")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 10)
                        
                        timeframePicker  // <--- we call our subview here
                        
                        let tvSymbol = parseBinancePair(coin.symbol)
                        if isSupportedSymbol(coin.symbol) {
                            TradingViewWebView(
                                symbol: "BINANCE:\(tvSymbol)",
                                timeframe: timeframe.rawValue
                            )
                            .aspectRatio(16/9, contentMode: .fit)
                            .clipped()
                        } else {
                            VStack {
                                Text("Chart Not Supported for \(coin.symbol.uppercased())")
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 260)
                        }
                        
                        CardView(cornerRadius: 6, paddingAmount: 6) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Market Stats")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Divider().background(Color.gray)
                                
                                HStack(alignment: .top, spacing: 20) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        let high = coin.high24h ?? 0
                                        let low  = coin.low24h ?? 0
                                        let change = coin.priceChangePercentage24h ?? 0
                                        Text("24H High: $\(high, specifier: "%.2f")")
                                            .foregroundColor(.white)
                                        Text("24H Low: $\(low, specifier: "%.2f")")
                                            .foregroundColor(.white)
                                        Text("Price Change (24h): \(change, specifier: "%.2f")%")
                                            .foregroundColor(change >= 0 ? .green : .red)
                                    }
                                    Spacer()
                                    VStack(alignment: .leading, spacing: 2) {
                                        let volume = coin.totalVolume ?? 0
                                        let mcap   = coin.marketCap ?? 0
                                        let supply = coin.circulatingSupply ?? 0
                                        Text("Volume: $\(volume, specifier: "%.0f")")
                                            .foregroundColor(.white)
                                        Text("Market Cap: $\(mcap, specifier: "%.0f")")
                                            .foregroundColor(.white)
                                        Text("Circ. Supply: \(supply, specifier: "%.0f")")
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        
                        CardView(cornerRadius: 6, paddingAmount: 6) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("AI Insights (Placeholder)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Divider().background(Color.gray)
                                Text("Coming soon! This is where Kevin’s LLM might provide insights on \(coin.symbol.uppercased()).")
                                    .foregroundColor(.gray)
                                    .font(.footnote)
                            }
                        }
                        
                        // Watchlist button
                        Button {
                            if homeVM.watchlistIDs.contains(coin.coinGeckoID) {
                                homeVM.removeFromWatchlist(coinID: coin.coinGeckoID)
                            } else {
                                homeVM.addToWatchlist(coinID: coin.coinGeckoID)
                            }
                            homeVM.refreshWatchlistData()
                        } label: {
                            Text(homeVM.watchlistIDs.contains(coin.coinGeckoID)
                                 ? "Remove from Watchlist"
                                 : "Add to Watchlist")
                                .font(.headline)
                                .padding()
                                .background(homeVM.watchlistIDs.contains(coin.coinGeckoID)
                                            ? Color.red.opacity(0.8)
                                            : Color.blue.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        // Trade button
                        if let tradeVM = tradeVM {
                            Button {
                                tradeVM.selectedSymbol = coin.symbol.uppercased() + "-USD"
                                UIApplication.shared.endEditing()
                                appState.selectedTab = .trade
                            } label: {
                                Text("Trade \(coin.symbol.uppercased())")
                                    .font(.headline)
                                    .padding()
                                    .background(Color.green.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        
                        Spacer().frame(height: 10)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarTitle("\(coin.symbol.uppercased())", displayMode: .inline)
    }
    
    // MARK: - Subview to fix type-checking issues
    @ViewBuilder
    private var timeframePicker: some View {
        Picker("Timeframe", selection: $timeframe) {
            Text("1H").tag(TradeTimeframe.oneHour)
            Text("1D").tag(TradeTimeframe.oneDay)
            Text("1W").tag(TradeTimeframe.oneWeek)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .onChange(of: timeframe) { newVal in
            // If you want to do something else with timeframe here
        }
    }
    
    func parseBinancePair(_ rawSymbol: String) -> String {
        let upper = rawSymbol.uppercased()
        if upper.contains("USD") {
            return upper.replacingOccurrences(of: "-", with: "")
        }
        return upper + "USDT"
    }
    
    func isSupportedSymbol(_ symbol: String) -> Bool {
        let supportedSet: Set<String> = [
            "BTC","ETH","SOL","XRP","BNB","DOGE","ADA","APT","ARB","TRX",
            "MATIC","DOT","SHIB","LINK","LTC","BCH","ATOM","FIL","AVAX",
            "UNI","XLM","SUI","PEPE","OP","QNT","GRT","ALGO","ICP","VET",
            "FTM","NEAR","AAVE","WBTC","TUSD","USDC","USDT","BUSD","DAI"
        ]
        return supportedSet.contains(symbol.uppercased())
    }
}

// MARK: - TRADINGVIEW WEBVIEW
@available(iOS 16.0, *)
struct TradingViewWebView: UIViewRepresentable {
    let symbol: String
    var timeframe: String? = nil
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        loadChart(into: webView)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        loadChart(into: uiView)
    }
    
    private func loadChart(into webView: WKWebView) {
        let interval = timeframe ?? "30"
        
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              body {
                margin:0;
                padding:0;
                background-color:#000000;
              }
            </style>
        </head>
        <body>
          <div id="tradingview_widget"></div>
          <script src="https://s3.tradingview.com/tv.js"></script>
          <script>
          new TradingView.widget({
            "width": "100%",
            "height": "100%",
            "symbol": "\(symbol)",
            "interval": "\(interval)",
            "timezone": "Etc/UTC",
            "theme": "dark",
            "style": "1",
            "locale": "en",
            "enable_publishing": false,
            "hide_top_toolbar": true,
            "hide_legend": false,
            "save_image": false,
            "container_id": "tradingview_widget"
          });
          </script>
        </body>
        </html>
        """
        
        webView.loadHTMLString(htmlString, baseURL: nil)
    }
}

// MARK: - TRADE VIEWMODEL
class TradeViewModel: ObservableObject {
    @Published var selectedSymbol: String = "BTC-USD"
    @Published var side: String = "Buy"
    @Published var orderType: String = "Market"
    @Published var quantity: String = ""
    @Published var limitPrice: String = ""
    @Published var stopPrice: String = ""
    @Published var trailingStop: String = ""
    
    @Published var chartTimeframe: String = "60"
    @Published var aiSuggestion: String = ""
    @Published var userBalance: Double = 5000.0
    
    func submitOrder() {
        aiSuggestion = "AI Suggestion: For \(selectedSymbol), consider a trailing stop at \(trailingStop)."
    }
    
    func applyFraction(_ fraction: Double) {
        // Hard-coded fallback
        let price = (Double(limitPrice) ?? 0) > 0 ? Double(limitPrice)! : 20000.0
        let amountToSpend = userBalance * fraction
        let coinQty = amountToSpend / price
        quantity = String(format: "%.4f", coinQty)
    }
}

// MARK: - TRADE VIEW (color-coded Buy/Sell)
@available(iOS 16.0, *)
struct TradeView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var tradeVM: TradeViewModel
    
    @State private var selectedTimeframe: TradeTimeframe = .oneHour
    @State private var showAdvancedTrading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 10) {
                        timeframeSegment  // subview to reduce complexity
                        
                        let processed = parseBinancePair(tradeVM.selectedSymbol)
                        TradingViewWebView(symbol: "BINANCE:\(processed)",
                                           timeframe: tradeVM.chartTimeframe)
                            .aspectRatio(16/9, contentMode: .fit)
                            .clipped()
                        
                        CardView(cornerRadius: 6, paddingAmount: 6) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Place an Order")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Balance: $\(tradeVM.userBalance, specifier: "%.2f")")
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                                
                                HStack {
                                    Picker("Symbol", selection: $tradeVM.selectedSymbol) {
                                        Text("BTC-USD").tag("BTC-USD")
                                        Text("ETH-USD").tag("ETH-USD")
                                        Text("SOL-USD").tag("SOL-USD")
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    
                                    Picker("Side", selection: $tradeVM.side) {
                                        Text("Buy").tag("Buy")
                                        Text("Sell").tag("Sell")
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                                
                                Picker("Order Type", selection: $tradeVM.orderType) {
                                    Text("Market").tag("Market")
                                    Text("Limit").tag("Limit")
                                    Text("Stop-Limit").tag("Stop-Limit")
                                    Text("Trailing Stop").tag("Trailing Stop")
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                
                                HStack {
                                    Text("Qty:")
                                        .foregroundColor(.white)
                                    TextField("0.0", text: $tradeVM.quantity)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                }
                                
                                if tradeVM.orderType == "Limit" || tradeVM.orderType == "Stop-Limit" {
                                    HStack {
                                        Text("Limit Price:")
                                            .foregroundColor(.white)
                                        TextField("0.0", text: $tradeVM.limitPrice)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.decimalPad)
                                    }
                                }
                                if tradeVM.orderType == "Stop-Limit" {
                                    HStack {
                                        Text("Stop Price:")
                                            .foregroundColor(.white)
                                        TextField("0.0", text: $tradeVM.stopPrice)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.decimalPad)
                                    }
                                }
                                if tradeVM.orderType == "Trailing Stop" {
                                    HStack {
                                        Text("Trailing Stop:")
                                            .foregroundColor(.white)
                                        TextField("0.0", text: $tradeVM.trailingStop)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.decimalPad)
                                    }
                                }
                                
                                // Quick % buttons
                                HStack {
                                    ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { fraction in
                                        Button {
                                            tradeVM.applyFraction(fraction)
                                        } label: {
                                            Text("\(Int(fraction * 100))%")
                                                .font(.subheadline)
                                                .padding(6)
                                                .frame(minWidth: 40)
                                                .background(Color.gray.opacity(0.2))
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                
                                Button {
                                    tradeVM.submitOrder()
                                } label: {
                                    Text("\(tradeVM.side) \(tradeVM.selectedSymbol)")
                                        .font(.headline)
                                        .padding()
                                        .background(tradeVM.side == "Buy" ? Color.green.opacity(0.8) : Color.red.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                
                                if !tradeVM.aiSuggestion.isEmpty {
                                    Text(tradeVM.aiSuggestion)
                                        .foregroundColor(.yellow)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .background(
                            tradeVM.side == "Buy"
                                ? Color.green.opacity(0.05)
                                : Color.red.opacity(0.05)
                        )
                        
                        Toggle("Show Advanced Trading", isOn: $showAdvancedTrading)
                            .padding(.horizontal)
                            .foregroundColor(.white)
                        
                        if showAdvancedTrading {
                            CardView(cornerRadius: 6, paddingAmount: 6) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Order Book (Placeholder)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Divider().background(Color.gray)
                                    
                                    let randomBids = (1...5).map { _ in (price: Double.random(in: 9700...9800), qty: Double.random(in: 0.1...1.0)) }
                                    let randomAsks = (1...5).map { _ in (price: Double.random(in: 9800...9900), qty: Double.random(in: 0.1...1.0)) }
                                    
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Bids").foregroundColor(.green)
                                            ForEach(randomBids, id: \.price) { bid in
                                                Text(String(format: "Price: %.2f, Qty: %.2f", bid.price, bid.qty))
                                                    .foregroundColor(.green)
                                                    .font(.caption)
                                            }
                                        }
                                        Spacer()
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Asks").foregroundColor(.red)
                                            ForEach(randomAsks, id: \.price) { ask in
                                                Text(String(format: "Price: %.2f, Qty: %.2f", ask.price, ask.qty))
                                                    .foregroundColor(.red)
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            CardView(cornerRadius: 6, paddingAmount: 6) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Depth Chart (Placeholder)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Divider().background(Color.gray)
                                    
                                    GeometryReader { geo in
                                        ZStack {
                                            Path { path in
                                                path.move(to: .zero)
                                                path.addLine(to: CGPoint(x: geo.size.width * 0.4, y: geo.size.height * 0.6))
                                                path.addLine(to: CGPoint(x: geo.size.width * 0.4, y: geo.size.height))
                                                path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                                                path.closeSubpath()
                                            }
                                            .fill(Color.red.opacity(0.3))
                                            
                                            Path { path in
                                                path.move(to: CGPoint(x: geo.size.width, y: 0))
                                                path.addLine(to: CGPoint(x: geo.size.width * 0.6, y: geo.size.height * 0.4))
                                                path.addLine(to: CGPoint(x: geo.size.width * 0.6, y: geo.size.height))
                                                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                                                path.closeSubpath()
                                            }
                                            .fill(Color.green.opacity(0.3))
                                        }
                                    }
                                    .frame(height: 120)
                                }
                                .frame(maxHeight: 180)
                            }
                            
                            CardView(cornerRadius: 6, paddingAmount: 6) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Exchange Trading Integration (Placeholder)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Divider().background(Color.gray)
                                    Text("In the future, integrate real exchange APIs (Binance, Coinbase, etc.) to place orders here.")
                                        .foregroundColor(.gray)
                                        .font(.footnote)
                                }
                            }
                        }
                        
                        Spacer().frame(height: 80)
                    }
                }
            }
            .navigationBarTitle("Trade", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // Subview for timeframe
    @ViewBuilder
    private var timeframeSegment: some View {
        Picker("Timeframe", selection: $selectedTimeframe) {
            Text("1H").tag(TradeTimeframe.oneHour)
            Text("1D").tag(TradeTimeframe.oneDay)
            Text("1W").tag(TradeTimeframe.oneWeek)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .onChange(of: selectedTimeframe) { newVal in
            tradeVM.chartTimeframe = newVal.rawValue
        }
    }
    
    func parseBinancePair(_ raw: String) -> String {
        let noDash = raw.uppercased().replacingOccurrences(of: "-", with: "")
        let removedUsd = noDash.replacingOccurrences(of: "USD", with: "")
        return removedUsd + "USDT"
    }
}

// MARK: - PORTFOLIO VIEW
@available(iOS 16.0, *)
struct PortfolioView: View {
    @State private var holdings: [Holding] = []
    @State private var showAddTxSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        let data = holdings.isEmpty ? sampleHoldings : holdings
                        let totalValue = data.reduce(0) { $0 + $1.totalValue }
                        
                        Text("Total Value: $\(totalValue, specifier: "%.2f")")
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                        
                        CardView(cornerRadius: 8, paddingAmount: 4) {
                            ZStack {
                                ringChart(for: data)
                                    .aspectRatio(1.0, contentMode: .fit)
                                Text("Distribution")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                            .frame(height: 260)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(data) { h in
                                CardView(cornerRadius: 6, paddingAmount: 6) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(h.symbol)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("Amount: \(h.amount, specifier: "%.4f")")
                                            .foregroundColor(.white.opacity(0.8))
                                        Text("Value: $\(h.totalValue, specifier: "%.2f")")
                                            .foregroundColor(.white.opacity(0.8))
                                        let pct = h.dailyChangePercent
                                        Text("Daily Change: \(pct >= 0 ? "+" : "")\(pct, specifier: "%.2f")%")
                                            .foregroundColor(pct >= 0 ? .green : .red)
                                            .font(.footnote)
                                    }
                                }
                            }
                        }
                        
                        Button {
                            showAddTxSheet = true
                        } label: {
                            Text("Add Transaction")
                                .font(.headline)
                                .padding()
                                .background(Color.blue.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        CardView(cornerRadius: 6, paddingAmount: 6) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Linked Accounts")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Link wallets/exchanges directly from your Portfolio (placeholder).")
                                    .foregroundColor(.gray)
                                    .font(.footnote)
                                
                                Button {
                                    // placeholder
                                } label: {
                                    Text("Link a Wallet/Exchange")
                                        .font(.subheadline)
                                        .padding(6)
                                        .background(Color.blue.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        CardView(cornerRadius: 6, paddingAmount: 6) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Advanced Portfolio Stats (Placeholder)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Divider().background(Color.gray)
                                Text("In the future, you could show performance or historical data.")
                                    .foregroundColor(.gray)
                                    .font(.footnote)
                            }
                        }
                        
                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                }
            }
            .navigationBarTitle("Portfolio", displayMode: .inline)
            .onAppear {
                loadHoldings()
            }
            .sheet(isPresented: $showAddTxSheet) {
                AddTransactionView { newHolding in
                    holdings.append(newHolding)
                    saveHoldings()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    var sampleHoldings: [Holding] {
        [
            Holding(symbol: "BTC", amount: 0.5,  totalValue: 15000, dailyChangePercent: 1.2),
            Holding(symbol: "ETH", amount: 2.0,  totalValue: 4200,  dailyChangePercent: -0.5),
            Holding(symbol: "DOGE", amount: 1000, totalValue: 90,   dailyChangePercent: 3.1)
        ]
    }
    
    func ringChart(for data: [Holding]) -> some View {
        let totalValue = data.reduce(0) { $0 + $1.totalValue }
        let segments = data.enumerated().map { (index, h) -> Segment in
            let fraction = totalValue == 0 ? 0 : h.totalValue / totalValue
            let color = chartColors[index % chartColors.count]
            return Segment(color: color, fraction: fraction, label: h.symbol)
        }
        
        return ZStack {
            ForEach(0..<segments.count, id: \.self) { i in
                let startAngle = angleUpToSegment(segments, i)
                let endAngle   = angleUpToSegment(segments, i+1)
                RingSlice(startAngle: startAngle, endAngle: endAngle, color: segments[i].color)
            }
        }
    }
    
    func angleUpToSegment(_ segments: [Segment], _ index: Int) -> Angle {
        let fraction = segments.prefix(index).map(\.fraction).reduce(0, +)
        return .degrees(fraction * 360)
    }
    
    let chartColors: [Color] = [.blue, .green, .purple, .orange, .pink, .red, .yellow]
    
    func saveHoldings() {
        do {
            let data = try JSONEncoder().encode(holdings)
            UserDefaults.standard.set(data, forKey: "holdingsData")
        } catch {
            print("Error encoding holdings: \(error)")
        }
    }
    
    func loadHoldings() {
        guard let data = UserDefaults.standard.data(forKey: "holdingsData") else { return }
        do {
            let decoded = try JSONDecoder().decode([Holding].self, from: data)
            self.holdings = decoded
        } catch {
            print("Error decoding holdings: \(error)")
        }
    }
}

// MARK: - AddTransactionView
@available(iOS 16.0, *)
struct AddTransactionView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var symbol = "BTC"
    @State private var amount = ""
    @State private var cost   = ""
    
    let onAdd: (Holding) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transaction Info")) {
                    TextField("Symbol", text: $symbol)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    TextField("Cost (USD)", text: $cost)
                        .keyboardType(.decimalPad)
                }
                
                Button("Add") {
                    let amt = Double(amount) ?? 0
                    let cst = Double(cost) ?? 0
                    let holding = Holding(symbol: symbol.uppercased(), amount: amt, totalValue: cst, dailyChangePercent: 0)
                    onAdd(holding)
                    dismiss()
                }
                .foregroundColor(.white)
                .padding(8)
                .background(Color.blue.opacity(0.8))
                .cornerRadius(8)
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - AI TAB (with Chat Persistence)
@available(iOS 16.0, *)
struct AITabView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var messages: [ChatMessage] = []
    @State private var userInput: String = ""
    @FocusState private var isInputFocused: Bool
    
    @State private var isRecording = false
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(messages) { msg in
                                ChatBubble(message: msg)
                                    .id(msg.id)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .frame(maxWidth: 800)
                        .onChange(of: messages.count) { _ in
                            if let lastID = messages.last?.id {
                                withAnimation {
                                    scrollProxy.scrollTo(lastID, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                .background(Color.black)
                
                // Input area
                VStack(spacing: 0) {
                    // Preset prompts
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(presetPrompts, id: \.self) { prompt in
                                Button(prompt) {
                                    userInput = prompt
                                    isInputFocused = false
                                }
                                .padding(6)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .background(Color.black)
                    
                    HStack(spacing: 4) {
                        ZStack {
                            if userInput.isEmpty {
                                Text("Ask anything about crypto...")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            TextEditor(text: $userInput)
                                .frame(minHeight: 36, maxHeight: 80)
                                .padding(4)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                                .focused($isInputFocused)
                        }
                        
                        // Paper plane
                        Button {
                            sendMessage()
                            isInputFocused = false
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.blue.opacity(0.8))
                                .cornerRadius(8)
                        }
                        
                        // Keyboard down
                        Button {
                            UIApplication.shared.endEditing()
                        } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(8)
                        }
                        
                        // Mic
                        Button(action: { toggleRecording() }) {
                            Image(systemName: isRecording ? "mic.fill" : "mic")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(isRecording ? .red : .white)
                                .padding(6)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(8)
                        }
                    }
                    .padding(6)
                    .background(Color.black)
                    .padding(.bottom, 80)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitle("AI Chat", displayMode: .inline)
            .toolbar {
                // "Clear Chat" button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear Chat") {
                        messages.removeAll()
                        saveChatHistory()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadChatHistory()
            if !messages.contains(where: { $0.role == .system }) {
                messages.insert(ChatMessage(role: .system, content: "Welcome to CryptoSage AI! Ask anything about crypto."), at: 0)
                saveChatHistory()
            }
        }
    }
    
    let presetPrompts = [
        "What are today’s biggest crypto gainers?",
        "What's my portfolio’s risk level?",
        "Explain BTC’s price movement in the last 24 hours."
    ]
    
    func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let userMsg = ChatMessage(role: .user, content: userInput)
        messages.append(userMsg)
        userInput = ""
        saveChatHistory()
        
        // Placeholder AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let aiReply = ChatMessage(role: .assistant, content: "This is a placeholder AI response.")
            messages.append(aiReply)
            saveChatHistory()
        }
    }
    
    // MARK: - Speech
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
        isRecording.toggle()
    }
    
    func startRecording() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            if authStatus == .authorized {
                do {
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                    
                    let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                    let inputNode = audioEngine.inputNode
                    recognitionRequest.shouldReportPartialResults = true
                    
                    recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                        if let result = result {
                            DispatchQueue.main.async {
                                self.userInput = result.bestTranscription.formattedString
                            }
                        }
                        if error != nil || (result?.isFinal ?? false) {
                            self.audioEngine.stop()
                            inputNode.removeTap(onBus: 0)
                            recognitionTask = nil
                        }
                    }
                    
                    let recordingFormat = inputNode.outputFormat(forBus: 0)
                    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                        recognitionRequest.append(buffer)
                    }
                    
                    audioEngine.prepare()
                    try audioEngine.start()
                } catch {
                    print("Error starting recording: \(error.localizedDescription)")
                }
            } else {
                print("Speech recognition not authorized.")
            }
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
    }
    
    // MARK: - Chat Persistence
    func saveChatHistory() {
        let mapped = messages.map { msg -> [String: String] in
            ["role": msg.roleString, "content": msg.content]
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: mapped, options: [])
            UserDefaults.standard.set(data, forKey: "aiChatHistory")
        } catch {
            print("Error encoding chat messages: \(error)")
        }
    }
    
    func loadChatHistory() {
        guard let data = UserDefaults.standard.data(forKey: "aiChatHistory") else { return }
        do {
            let raw = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: String]] ?? []
            let restored = raw.compactMap { dict -> ChatMessage? in
                guard let roleString = dict["role"],
                      let content = dict["content"] else { return nil }
                let role: MessageRole
                switch roleString {
                case "assistant": role = .assistant
                case "system":    role = .system
                default:          role = .user
                }
                return ChatMessage(role: role, content: content)
            }
            self.messages = restored
        } catch {
            print("Error decoding chat messages: \(error)")
        }
    }
}

// MARK: - SETTINGS VIEW
@available(iOS 16.0, *)
struct SettingsView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var appState: AppState
    
    @State private var notificationsEnabled = true
    @State private var autoDarkMode = true
    @State private var connectedExchanges: [String] = []
    
    @State private var selectedCurrency = "USD"
    @State private var aiTuning = "Conservative"
    
    @State private var showLinkSheet = false
    
    @State private var priceAlertsEnabled = false
    @State private var showAdvancedExchange = false
    
    // AI personality slider (placeholder)
    @State private var aiPersonality: Double = 0.5
    
    var body: some View {
        Form {
            Section(header: Text("General").foregroundColor(.white)) {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                Toggle("Dark Mode On?", isOn: $appState.isDarkMode)
            }
            
            Section(header: Text("Price Alerts").foregroundColor(.white)) {
                Toggle("Enable Price Alerts", isOn: $priceAlertsEnabled)
                    .foregroundColor(.white)
                if priceAlertsEnabled {
                    Text("You can configure custom alerts in the future.")
                        .foregroundColor(.gray)
                        .font(.footnote)
                }
            }
            
            Section(header: Text("Preferences").foregroundColor(.white)) {
                Picker("Currency Preference", selection: $selectedCurrency) {
                    Text("USD").tag("USD")
                    Text("EUR").tag("EUR")
                    Text("BTC").tag("BTC")
                }
                .pickerStyle(.segmented)
                
                Picker("AI Trading Style", selection: $aiTuning) {
                    Text("Aggressive").tag("Aggressive")
                    Text("Conservative").tag("Conservative")
                }
                .pickerStyle(.segmented)
                
                VStack(alignment: .leading) {
                    Text("AI Personality").foregroundColor(.white)
                    Slider(value: $aiPersonality, in: 0.0...1.0, step: 0.1)
                    Text("Value: \(aiPersonality, specifier: "%.1f") (placeholder)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            
            Section(header: Text("Connected Exchanges").foregroundColor(.white)) {
                if connectedExchanges.isEmpty {
                    Text("No exchanges linked.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(connectedExchanges, id: \.self) { ex in
                        Text(ex)
                    }
                }
                
                Button {
                    showLinkSheet = true
                } label: {
                    HStack {
                        Image(systemName: "link")
                        Text("Link New Exchange")
                    }
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(8)
                }
            }
            
            Section(header: Text("Advanced Exchange Settings").foregroundColor(.white)) {
                Toggle("Show Advanced Exchange Options", isOn: $showAdvancedExchange)
                if showAdvancedExchange {
                    Text("Future expansions: real trading, API key usage, etc.")
                        .foregroundColor(.gray)
                        .font(.footnote)
                }
            }
            
            Section(header: Text("Wallets").foregroundColor(.white)) {
                NavigationLink(destination: WalletsView().environmentObject(homeVM)) {
                    Text("Manage Wallets")
                }
            }
            
            Section(footer:
                Text("Additional preferences can go here, like region, advanced AI settings, etc.")
                    .foregroundColor(.gray)
            ) {
                EmptyView()
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .foregroundColor(.white)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLinkSheet) {
            LinkExchangeView { newExchange in
                connectedExchanges.append(newExchange)
            }
        }
    }
}

// MARK: - LINK EXCHANGE VIEW
@available(iOS 16.0, *)
struct LinkExchangeView: View {
    @Environment(\.dismiss) var dismiss
    @State private var exchangeName = ""
    @State private var apiKey = ""
    @State private var apiSecret = ""
    
    let onLink: (String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exchange Info")) {
                    TextField("Exchange Name", text: $exchangeName)
                    TextField("API Key", text: $apiKey)
                    SecureField("API Secret", text: $apiSecret)
                }
                
                Button("Link Exchange") {
                    guard !exchangeName.isEmpty else { return }
                    onLink(exchangeName)
                    dismiss()
                }
                .foregroundColor(.white)
                .padding(8)
                .background(Color.green.opacity(0.8))
                .cornerRadius(8)
            }
            .navigationTitle("Link Exchange")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - WALLET CODE
struct UserWallet: Identifiable, Codable {
    let id = UUID()
    let address: String
    let label: String
}

@available(iOS 16.0, *)
struct WalletsView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    
    @State private var newLabel   = ""
    @State private var newAddress = ""
    
    var body: some View {
        VStack {
            Text("Your Wallets")
                .font(.title2)
                .foregroundColor(.white)
                .padding(.top, 10)
            
            if homeVM.userWallets.isEmpty {
                Text("No wallets yet.")
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            } else {
                List {
                    ForEach(homeVM.userWallets) { w in
                        VStack(alignment: .leading) {
                            Text(w.label)
                                .foregroundColor(.white)
                                .font(.headline)
                            Text(w.address)
                                .foregroundColor(.gray)
                                .font(.footnote)
                        }
                        .listRowBackground(Color.black)
                        .onTapGesture {
                            print("Tapped wallet: \(w.address)")
                        }
                    }
                    .onDelete { indexSet in
                        homeVM.userWallets.remove(atOffsets: indexSet)
                        homeVM.saveUserWallets()
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.black)
            }
            
            HStack {
                TextField("Label", text: $newLabel)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)
                
                TextField("Address", text: $newAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Add") {
                    guard !newAddress.isEmpty else { return }
                    let wallet = UserWallet(address: newAddress, label: newLabel.isEmpty ? "Wallet" : newLabel)
                    homeVM.userWallets.append(wallet)
                    homeVM.saveUserWallets()
                    
                    newAddress = ""
                    newLabel   = ""
                }
                .padding(6)
                .background(Color.blue.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
        }
        .background(Color.black)
        .navigationTitle("Manage Wallets")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - HOME VIEWMODEL
class HomeViewModel: ObservableObject {
    @Published var coins: [CoinGeckoCoin] = []
    @Published var watchlistCoins: [CoinGeckoCoin] = []
    @Published var news: [NewsItem] = []
    @Published var isLoadingCoins = false
    @Published var isLoadingNews = false
    
    @Published var trendingCoins: [TrendingCoin] = []
    
    // user-starred coin IDs
    @Published var watchlistIDs: Set<String> = ["bitcoin", "ethereum", "solana"]
    @Published var showSettings = false
    
    // WALLET SUPPORT
    @Published var userWallets: [UserWallet] = []
    
    func loadUserWallets() {
        guard let data = UserDefaults.standard.data(forKey: "userWalletsData") else { return }
        do {
            let decoded = try JSONDecoder().decode([UserWallet].self, from: data)
            self.userWallets = decoded
        } catch {
            print("Error decoding userWallets: \(error)")
        }
    }
    
    func saveUserWallets() {
        do {
            let data = try JSONEncoder().encode(userWallets)
            UserDefaults.standard.set(data, forKey: "userWalletsData")
        } catch {
            print("Error encoding userWallets: \(error)")
        }
    }
    
    func refreshWatchlistData() {
        let joinedIDs = watchlistIDs.joined(separator: ",")
        if joinedIDs.isEmpty {
            DispatchQueue.main.async {
                self.watchlistCoins = []
            }
            return
        }
        
        let urlString = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=\(joinedIDs)&order=market_cap_desc&per_page=100&page=1&sparkline=false"
        guard let url = URL(string: urlString) else { return }
        
        self.isLoadingCoins = true
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoadingCoins = false
            }
            if let error = error {
                print("Error fetching watchlist data: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode([CoinGeckoCoin].self, from: data)
                DispatchQueue.main.async {
                    self.watchlistCoins = decoded
                }
            } catch {
                print("Error decoding watchlist data: \(error)")
            }
        }.resume()
    }
    
    func fetchCoins() {
        isLoadingCoins = true
        guard let url = URL(string:
            "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=bitcoin,ethereum,solana&order=market_cap_desc&per_page=3&page=1&sparkline=false"
        ) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoadingCoins = false
            }
            if let error = error {
                print("Error fetching coins: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode([CoinGeckoCoin].self, from: data)
                DispatchQueue.main.async {
                    self.coins = decoded
                }
            } catch {
                print("Error decoding coins: \(error)")
            }
        }.resume()
    }
    
    func fetchNews() {
        isLoadingNews = true
        guard let url = URL(string: "https://min-api.cryptocompare.com/data/v2/news/?lang=EN") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoadingNews = false
            }
            if let error = error {
                print("Error fetching news: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode(CryptoCompareNewsResponse.self, from: data)
                let mapped = decoded.Data.prefix(5).map { item -> NewsItem in
                    let possibleURL = URL(string: item.url)
                    return NewsItem(
                        title: item.title,
                        source: item.source,
                        url: possibleURL
                    )
                }
                DispatchQueue.main.async {
                    self.news = Array(mapped)
                }
            } catch {
                print("Error decoding news: \(error)")
            }
        }.resume()
    }
    
    func fetchTrending() {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/search/trending") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error fetching trending: \(error)")
                return
            }
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode(TrendingResponse.self, from: data)
                let mapped = decoded.coins.map { coin -> TrendingCoin in
                    let rawPrice = coin.item.priceBtc
                    let finalPrice = (rawPrice > 0) ? (rawPrice * 27000) : 0.0
                    return TrendingCoin(
                        id: coin.item.id,
                        symbol: coin.item.symbol,
                        price: finalPrice,
                        priceChange24h: Double.random(in: -10...10)
                    )
                }
                DispatchQueue.main.async {
                    self.trendingCoins = mapped
                }
            } catch {
                print("Error decoding trending: \(error)")
            }
        }.resume()
    }
    
    func fetchCoinByID(_ coinID: String, completion: @escaping (CoinGeckoCoin?) -> Void) {
        let urlString = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=\(coinID)&order=market_cap_desc&per_page=1&page=1&sparkline=false"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("fetchCoinByID error: \(error)")
                completion(nil)
                return
            }
            guard let data = data else {
                completion(nil)
                return
            }
            do {
                let result = try JSONDecoder().decode([CoinGeckoCoin].self, from: data)
                completion(result.first)
            } catch {
                print("Error decoding single coin: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    func addToWatchlist(coinID: String) {
        watchlistIDs.insert(coinID)
    }
    
    func removeFromWatchlist(coinID: String) {
        watchlistIDs.remove(coinID)
    }
}

// MARK: - MODELS
struct CoinGeckoCoin: Decodable, Identifiable {
    var id = UUID()
    let coinGeckoID: String
    let symbol: String
    let name: String?
    let currentPrice: Double?
    let priceChangePercentage24h: Double?
    let high24h: Double?
    let low24h: Double?
    let totalVolume: Double?
    let marketCap: Double?
    let circulatingSupply: Double?
    
    enum CodingKeys: String, CodingKey {
        case coinGeckoID = "id"
        case symbol
        case name
        case currentPrice = "current_price"
        case priceChangePercentage24h = "price_change_percentage_24h"
        case high24h = "high_24h"
        case low24h  = "low_24h"
        case totalVolume = "total_volume"
        case marketCap   = "market_cap"
        case circulatingSupply = "circulating_supply"
    }
}

struct TrendingResponse: Decodable {
    let coins: [TrendingCoinWrapper]
    struct TrendingCoinWrapper: Decodable {
        let item: TrendingItem
    }
}

struct TrendingItem: Decodable {
    let id: String
    let symbol: String
    let priceBtc: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case priceBtc = "price_btc"
    }
}

struct TrendingCoin: Identifiable {
    let id: String
    let symbol: String
    let price: Double
    let priceChange24h: Double
    
    var uniqueID = UUID()
    var identity: UUID { uniqueID }
}

struct CryptoCompareNewsResponse: Decodable {
    let Data: [CryptoCompareNewsItem]
}

struct CryptoCompareNewsItem: Decodable {
    let title: String
    let source: String
    let url: String
}

struct NewsItem: Identifiable {
    let id = UUID()
    let title: String
    let source: String
    let url: URL?
}

struct MarketItem: Identifiable {
    let id = UUID()
    let symbol: String
    let price: Double
    let change: Double
}

struct Holding: Identifiable, Codable {
    let id = UUID()
    var symbol: String
    var amount: Double
    var totalValue: Double
    var dailyChangePercent: Double
}

// MARK: - Pie Chart
struct Segment {
    let color: Color
    let fraction: Double
    let label: String
}

struct RingSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                let radius = min(geo.size.width, geo.size.height) / 2
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
            }
            .stroke(color, lineWidth: 20)
        }
    }
}

// MARK: - AI Chat Models
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    
    var roleString: String {
        switch role {
        case .assistant: return "assistant"
        case .system:    return "system"
        case .user:      return "user"
        }
    }
}

enum MessageRole {
    case user, assistant, system
}

// MARK: - Chat Bubble
@available(iOS 16.0, *)
struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .assistant || message.role == .system {
                VStack(alignment: .leading) {
                    Text(message.content)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                Spacer()
            } else {
                Spacer()
                VStack(alignment: .trailing) {
                    Text(message.content)
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Color.yellow.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }
}

// MARK: - Reusable CardView
@available(iOS 16.0, *)
struct CardView<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 8
    var paddingAmount: CGFloat = 8
    
    init(cornerRadius: CGFloat = 8,
         paddingAmount: CGFloat = 8,
         @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.paddingAmount = paddingAmount
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        .padding(paddingAmount)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.white.opacity(0.05), .white.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(cornerRadius)
        .shadow(color: .white.opacity(0.15), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Watchlist Row
@available(iOS 16.0, *)
struct WatchlistRow: View {
    let item: MarketItem
    
    var body: some View {
        HStack {
            Text(item.symbol)
                .foregroundColor(.white)
                .font(.headline)
            Spacer()
            Text("$\(formatPrice(item.price, symbol: item.symbol))")
                .foregroundColor(.white)
            let sign = item.change >= 0 ? "+" : ""
            Text("\(sign)\(item.change, specifier: "%.2f")%")
                .foregroundColor(item.change >= 0 ? .green : .red)
                .padding(.leading, 6)
        }
        .padding(.vertical, 4)
    }
    
    func formatPrice(_ price: Double, symbol: String) -> String {
        let upper = symbol.uppercased()
        if upper.contains("BTC") || upper.contains("ETH") || upper.contains("SOL") {
            return String(format: "%.2f", price)
        } else {
            return String(format: "%.4f", price)
        }
    }
}

// MARK: - Trending Card
@available(iOS 16.0, *)
struct TrendingCard: View {
    let item: MarketItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.symbol)
                .font(.headline)
                .foregroundColor(.white)
            Text("$\(item.price, specifier: "%.8f")")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            let sign = item.change >= 0 ? "+" : ""
            Text("\(sign)\(item.change, specifier: "%.2f")%")
                .font(.footnote)
                .foregroundColor(item.change >= 0 ? .green : .red)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(item.change >= 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
        )
    }
}
