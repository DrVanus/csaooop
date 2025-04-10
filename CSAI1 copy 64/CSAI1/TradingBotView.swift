import SwiftUI
// Replace or import your actual AI chat components here if needed:
// import AiChatModule

// MARK: - TradingBotView
struct TradingBotView: View {
    // MARK: - Bot Creation Modes
    enum BotCreationMode: String, CaseIterable {
        case aiChat = "AI Chat"
        case dcaBot = "DCA Bot"
        case gridBot = "Grid Bot"
        case signalBot = "Signal Bot"
    }
    
    // MARK: - State Variables
    @State private var selectedMode: BotCreationMode = .aiChat
    
    // MARK: - For AI Chat – now using the shared view model from your repository
    @StateObject private var aiChatVM = AiChatViewModel()  // Use your final AI chat view model from GitHub
    
    // MARK: - DCA Bot State
    @State private var botName: String = ""
    @State private var selectedExchange: String = "Binance"
    @State private var selectedDirection: String = "Long"
    @State private var selectedBotType: String = "Single-pair"
    @State private var selectedProfitCurrency: String = "Quote"
    @State private var selectedTradingPairDCA: String = "BTC_USDT"
    
    @State private var baseOrderSize: String = ""
    @State private var selectedStartOrderType: String = "Market"
    @State private var selectedTradeCondition: String = "RSI"
    
    @State private var averagingOrderSize: String = ""
    @State private var priceDeviation: String = ""
    @State private var maxAveragingOrders: String = ""
    @State private var averagingOrderStepMultiplier: String = ""
    
    @State private var takeProfit: String = ""
    @State private var selectedTakeProfitType: String = "Single Target"
    @State private var trailingEnabled: Bool = false
    @State private var revertProfit: Bool = false
    @State private var stopLossEnabled: Bool = false
    @State private var stopLossValue: String = ""
    @State private var maxHoldPeriod: String = ""
    
    @State private var isAdvancedViewExpanded: Bool = false
    @State private var balanceInfo: String = "0.00 USDT"
    @State private var maxAmountForBotUsage: String = ""
    @State private var maxAveragingPriceDeviation: String = ""
    
    // MARK: - Grid Bot State
    @State private var gridBotName: String = ""
    @State private var gridSelectedExchange: String = "Binance"
    @State private var gridSelectedTradingPair: String = "BTC_USDT"
    @State private var gridLowerPrice: String = ""
    @State private var gridUpperPrice: String = ""
    @State private var gridLevels: String = ""
    @State private var gridOrderVolume: String = ""
    @State private var gridTakeProfit: String = ""
    @State private var gridStopLossEnabled: Bool = false
    @State private var gridStopLossValue: String = ""
    
    // MARK: - Signal Bot State
    @State private var signalBotName: String = ""
    @State private var signalSelectedExchange: String = "Binance"
    @State private var signalSelectedPairs: String = "BTC_USDT"
    @State private var signalMaxUsage: String = ""
    @State private var signalPriceDeviation: String = ""
    @State private var signalEntriesLimit: String = ""
    @State private var signalTakeProfit: String = ""
    @State private var signalStopLossEnabled: Bool = false
    @State private var signalStopLossValue: String = ""
    
    // MARK: - Option Arrays for Pickers
    private let exchangeOptions = ["Binance", "Coinbase", "KuCoin", "Bitfinex"]
    private let directionOptions = ["Long", "Short", "Neutral"]
    private let botTypeOptions = ["Single-pair", "Multi-pair"]
    private let profitCurrencyOptions = ["Quote", "Base"]
    private let tradingPairsOptions = ["BTC_USDT", "ETH_USDT", "SOL_USDT", "ADA_USDT"]
    
    private let startOrderTypes = ["Market", "Limit", "Stop", "Stop-Limit"]
    private let tradeConditions = ["RSI", "QFL", "MACD", "Custom Condition"]
    private let takeProfitTypes = ["Single Target", "Multiple Targets", "Trailing TP"]
    
    // MARK: - Environment
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            customNavBar
            switch selectedMode {
            case .aiChat:
                // Use your final AI chat page from your repository to maintain consistent design.
                AiChatTabView(viewModel: aiChatVM)
            case .dcaBot:
                dcaBotView
            case .gridBot:
                gridBotView
            case .signalBot:
                signalBotView
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Custom Navigation Bar and Top Items
extension TradingBotView {
    private var customNavBar: some View {
        VStack(spacing: 0) {
            // Top row: back button, title, and Manage link.
            HStack {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.yellow)
                }
                .frame(width: 44, height: 44)
                Spacer()
                Text("Trading Bot")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                NavigationLink(destination: BotManagementView()) {
                    Text("Manage")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.yellow)
                }
                .frame(width: 70, height: 44)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            // Segmented control for mode selection
            Picker("", selection: $selectedMode) {
                ForEach(BotCreationMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1),
                alignment: .bottom
            )
        }
        .background(Color.black)
    }
}

// MARK: - AI Chat View (Reusing Final Components)
// Replace the code below with your exact AI chat components (e.g., AiChatTabView) from your GitHub repo.
struct AiChatTabView: View {
    @ObservedObject var viewModel: AiChatViewModel  // Your final AI chat view model
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.messages) { message in
                        // Reuse your final chat bubble design which includes timestamps, etc.
                        AiChatBubble(message: message)
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal, 16)
            }
            .background(Color.black)
            MyAIChatInputBar(text: $viewModel.userInput, onSend: { text in
                viewModel.sendMessage(text)
            })
        }
        .background(Color.black)
        .onAppear {
            viewModel.fetchInitialMessageIfNeeded()
        }
    }
}

// MARK: - (Placeholder) AI Chat Model & Components
// These are placeholders. Replace them with your exact implementations from your GitHub repository.

class AiChatViewModel: ObservableObject {
    @Published var messages: [AiChatMessage] = []
    @Published var userInput: String = ""
    
    func fetchInitialMessageIfNeeded() {
        if messages.isEmpty {
            let initial = AiChatMessage(
                text: "Hello! I'm your AI trading assistant. Would you like to configure a DCA Bot, a Grid Bot, or something else?",
                isUser: false,
                timestamp: Date()
            )
            messages.append(initial)
        }
    }
    
    func sendMessage(_ text: String) {
        let userMsg = AiChatMessage(text: text, isUser: true, timestamp: Date())
        messages.append(userMsg)
        // Simulate AI response; replace with your LLM call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let aiMsg = AiChatMessage(text: "AI response: \(text)", isUser: false, timestamp: Date())
            self.messages.append(aiMsg)
        }
    }
}

struct AiChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
}

struct AiChatBubble: View {
    let message: AiChatMessage
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
            Text(message.text)
                .padding()
                .foregroundColor(.white)
                .background(message.isUser ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                .cornerRadius(12)
            Text(formattedTimestamp(message.timestamp))
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
        .padding(message.isUser ? .leading : .trailing, 40)
        .padding(.vertical, 2)
    }
    
    private func formattedTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MyAIChatInputBar: View {
    @Binding var text: String
    var onSend: (String) -> Void
    
    var body: some View {
        HStack {
            TextField("Enter your strategy...", text: $text)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
            Button("Send") {
                guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                onSend(text)
                text = ""
            }
            .foregroundColor(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.yellow)
            .cornerRadius(12)
        }
        .padding()
    }
}

// MARK: - DCA Bot View
extension TradingBotView {
    private var dcaBotView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MAIN Section
                Group {
                    sectionHeader("Main")
                    textFieldRow(title: "Bot Name", text: $botName)
                    labelPickerRow(title: "Exchange", selection: $selectedExchange, options: exchangeOptions)
                    HStack(spacing: 20) {
                        labelPickerRow(title: "Direction", selection: $selectedDirection, options: directionOptions)
                        labelPickerRow(title: "Bot Type", selection: $selectedBotType, options: botTypeOptions)
                    }
                    HStack(spacing: 20) {
                        labelPickerRow(title: "Trading Pairs", selection: $selectedTradingPairDCA, options: tradingPairsOptions)
                        labelPickerRow(title: "Profit Currency", selection: $selectedProfitCurrency, options: profitCurrencyOptions)
                    }
                }
                
                // ENTRY Section
                Group {
                    sectionHeader("Entry Order")
                    textFieldRow(title: "Base Order Size", text: $baseOrderSize)
                    labelPickerRow(title: "Start Order Type", selection: $selectedStartOrderType, options: startOrderTypes)
                    labelPickerRow(title: "Trade Start Condition", selection: $selectedTradeCondition, options: tradeConditions)
                }
                
                // AVERAGING Section
                Group {
                    sectionHeader("Averaging Order")
                    textFieldRow(title: "Averaging Order Size", text: $averagingOrderSize)
                    textFieldRow(title: "Price Deviation", text: $priceDeviation)
                    textFieldRow(title: "Max Averaging Orders", text: $maxAveragingOrders)
                    textFieldRow(title: "Averaging Order Step Multiplier", text: $averagingOrderStepMultiplier)
                }
                
                // EXIT Section
                Group {
                    sectionHeader("Exit Order")
                    textFieldRow(title: "Take Profit (%)", text: $takeProfit)
                    labelPickerRow(title: "Take Profit Type", selection: $selectedTakeProfitType, options: takeProfitTypes)
                    
                    Toggle(isOn: $trailingEnabled) {
                        Text("Trailing").foregroundColor(.white)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.yellow))
                    
                    Toggle(isOn: $revertProfit) {
                        Text("Reinvert Profit").foregroundColor(.white)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.yellow))
                    
                    Toggle(isOn: $stopLossEnabled) {
                        Text("Stop Loss").foregroundColor(.white)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.yellow))
                    
                    if stopLossEnabled {
                        textFieldRow(title: "Stop Loss (%)", text: $stopLossValue)
                        textFieldRow(title: "Max Hold Period (days)", text: $maxHoldPeriod)
                    }
                }
                
                // ADVANCED Section
                Group {
                    sectionHeader("Advanced")
                    DisclosureGroup(isExpanded: $isAdvancedViewExpanded) {
                        textFieldRow(title: "Balance", text: $balanceInfo, disabled: true)
                        textFieldRow(title: "Max Amount for Bot Usage", text: $maxAmountForBotUsage)
                        textFieldRow(title: "Max Averaging Price Deviation", text: $maxAveragingPriceDeviation)
                    } label: {
                        Text("Advanced Settings")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.yellow)
                    }
                    .accentColor(.yellow)
                }
                
                // SUMMARY Section
                Group {
                    sectionHeader("Summary")
                    VStack(spacing: 6) {
                        Text("Balance: \(balanceInfo)").foregroundColor(.white)
                        Text("Max for bot usage: \(maxAmountForBotUsage.isEmpty ? "N/A" : maxAmountForBotUsage)")
                            .foregroundColor(.white)
                        Text("Price deviation: \(maxAveragingPriceDeviation.isEmpty ? "N/A" : maxAveragingPriceDeviation)")
                            .foregroundColor(.white)
                    }
                }
                
                // CREATE BUTTON
                Button {
                    createDcaBot()
                } label: {
                    Text("Create DCA Bot")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundColor(.white)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.top, 10)
                
                Spacer(minLength: 30)
            }
            .padding(16)
        }
        .background(Color.black)
    }
    
    private func createDcaBot() {
        print("DCA Bot created: \(botName), Exchange: \(selectedExchange), Direction: \(selectedDirection), Pair: \(selectedTradingPairDCA)")
    }
}

// MARK: - Grid Bot View
extension TradingBotView {
    private var gridBotView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    sectionHeader("Main")
                    textFieldRow(title: "Grid Bot Name", text: $gridBotName)
                    labelPickerRow(title: "Exchange", selection: $gridSelectedExchange, options: exchangeOptions)
                    labelPickerRow(title: "Trading Pair", selection: $gridSelectedTradingPair, options: tradingPairsOptions)
                }
                Group {
                    sectionHeader("Grid Settings")
                    textFieldRow(title: "Lower Price", text: $gridLowerPrice, placeholder: "e.g. 30000")
                    textFieldRow(title: "Upper Price", text: $gridUpperPrice, placeholder: "e.g. 40000")
                    textFieldRow(title: "Grid Levels", text: $gridLevels, placeholder: "Number of grid levels")
                    textFieldRow(title: "Order Volume", text: $gridOrderVolume, placeholder: "Volume per grid order")
                }
                Group {
                    sectionHeader("Exit Settings")
                    textFieldRow(title: "Take Profit (%)", text: $gridTakeProfit)
                    Toggle(isOn: $gridStopLossEnabled) {
                        Text("Enable Stop Loss").foregroundColor(.white)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.yellow))
                    if gridStopLossEnabled {
                        textFieldRow(title: "Stop Loss (%)", text: $gridStopLossValue)
                    }
                }
                Button {
                    createGridBot()
                } label: {
                    Text("Create Grid Bot")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundColor(.white)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.top, 10)
                Spacer(minLength: 30)
            }
            .padding(16)
        }
        .background(Color.black)
    }
    
    private func createGridBot() {
        print("Grid Bot created: \(gridBotName), Exchange: \(gridSelectedExchange), Pair: \(gridSelectedTradingPair)")
    }
}

// MARK: - Signal Bot View
extension TradingBotView {
    private var signalBotView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    sectionHeader("Main")
                    textFieldRow(title: "Signal Bot Name", text: $signalBotName)
                    labelPickerRow(title: "Exchange", selection: $signalSelectedExchange, options: exchangeOptions)
                    labelPickerRow(title: "Pairs", selection: $signalSelectedPairs, options: tradingPairsOptions)
                }
                Group {
                    sectionHeader("Settings")
                    textFieldRow(title: "Max Investment Usage", text: $signalMaxUsage, placeholder: "e.g. 500 USD")
                    textFieldRow(title: "Price Deviation", text: $signalPriceDeviation)
                    textFieldRow(title: "Max Entry Orders", text: $signalEntriesLimit, placeholder: "Number of entry orders")
                }
                Group {
                    sectionHeader("Exit Settings")
                    textFieldRow(title: "Take Profit (%)", text: $signalTakeProfit)
                    Toggle(isOn: $signalStopLossEnabled) {
                        Text("Stop Loss Enabled").foregroundColor(.white)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.yellow))
                    if signalStopLossEnabled {
                        textFieldRow(title: "Stop Loss (%)", text: $signalStopLossValue)
                    }
                }
                Button {
                    createSignalBot()
                } label: {
                    Text("Create Signal Bot")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundColor(.white)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.top, 10)
                Spacer(minLength: 30)
            }
            .padding(16)
        }
        .background(Color.black)
    }
    
    private func createSignalBot() {
        print("Signal Bot created: \(signalBotName), Exchange: \(signalSelectedExchange), Pairs: \(signalSelectedPairs)")
    }
}

// MARK: - Shared Helpers
extension TradingBotView {
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.yellow)
    }
    
    private func textFieldRow(title: String,
                              text: Binding<String>,
                              placeholder: String? = nil,
                              disabled: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
            TextField(placeholder ?? title, text: text)
                .disabled(disabled)
                .padding(12)
                .background(disabled ? Color.gray.opacity(0.3) : Color.white.opacity(0.1))
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
    
    private func labelPickerRow(title: String,
                                selection: Binding<String>,
                                options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .accentColor(.yellow)
            .padding(10)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

// MARK: - Chat Message Model
extension TradingBotView {
    struct ChatMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
    }
}

// MARK: - Bot Management View
struct BotManagementView: View {
    struct Bot: Identifiable {
        let id: String
        let name: String
        let exchange: String
        let type: String
        let status: String
    }
    
    @StateObject private var botsVM = BotsViewModel()
    
    var body: some View {
        List(botsVM.bots) { bot in
            HStack {
                VStack(alignment: .leading) {
                    Text(bot.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("\(bot.exchange) • \(bot.type)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("Status: \(bot.status)")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                Spacer()
                Button("Stop") {
                    botsVM.stopBot(bot.id)
                }
                .foregroundColor(.red)
            }
            .padding(.vertical, 6)
        }
        .listStyle(PlainListStyle())
        .background(Color.black)
        .navigationTitle("My Bots")
        .onAppear {
            botsVM.loadBots()
        }
    }
}

class BotsViewModel: ObservableObject {
    @Published var bots: [BotManagementView.Bot] = []
    
    func loadBots() {
        // Replace this with your real API call to load bots.
        self.bots = [
            BotManagementView.Bot(id: "1", name: "DCA Bot A", exchange: "Binance", type: "DCA", status: "Active"),
            BotManagementView.Bot(id: "2", name: "Grid Bot B", exchange: "Coinbase", type: "Grid", status: "Active")
        ]
    }
    
    func stopBot(_ id: String) {
        // Replace with your API call to stop the bot.
        print("Stopping bot with id \(id)")
        loadBots()
    }
}

// MARK: - Preview
struct TradingBotView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TradingBotView()
        }
        .preferredColorScheme(.dark)
    }
}
