//
//  MoreActionsView.swift
//  BankApp
//
//  Created by Вадим Семибратов on 03.06.2025.
//

import SwiftUI
import CoreData
import Alamofire

// MARK: - View
struct MoreActionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var currencyService = CurrencyService()
    @State private var showPredictView = false
    @State private var isInitialized = false
    @State private var timer: Timer?

    var body: some View {
        NavigationStack {
            NavigationLink(destination: PredictView(), isActive: $showPredictView) {
                EmptyView()
            }.hidden()

            ZStack(alignment: .top) {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.06, green: 0.04, blue: 0.15),
                        Color(red: 0.15, green: 0.08, blue: 0.35),
                        Color(red: 0.25, green: 0.13, blue: 0.45)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ).ignoresSafeArea()

                VStack(spacing: 0) {
                    headerView()

                    if currencyService.isLoading {
                        ProgressView().padding()
                    } else if let error = currencyService.error {
                        ErrorView(error: error)
                    } else {
                        ScrollView {
                            contentView
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                if !isInitialized {
                    currencyService.fetchLatestRates(context: viewContext)
                    startTimer()
                    isInitialized = true
                }
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(currencyService.currencyData) { currency in
                CurrencyCardView(currency: currency)
            }

            TopCurrenciesView(
                title: "📈 Топ рост",
                currencies: currencyService.topGainers,
                gradientColors: [Color.green.opacity(0.4)]
            ).padding(.horizontal)

            TopCurrenciesView(
                title: "📉 Топ падение",
                currencies: currencyService.topLosers,
                gradientColors: [Color.red.opacity(0.4)]
            ).padding(.horizontal)

            Button(action: { showPredictView = true }) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Прогноз цен")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.7))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .padding(.top)
    }

    private func headerView() -> some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .ignoresSafeArea(edges: .top)
                .frame(height: 56)

            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18))
                Text("Курсы валют")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)

            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
                Spacer()
            }
            .padding(.horizontal)
        }
        .frame(height: 56)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            currencyService.fetchLatestRates(context: viewContext)
        }
    }
}



// MARK: - Currency Service
class CurrencyService: ObservableObject {
    @Published var currencyData: [CurrencyData] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let apiKey = "deacf4eb8c4f35e2bcda9bc8" // Замените на ваш ключ
    private let baseCurrency = "RUB"
    private let targetCurrencies = ["USD", "EUR", "CNY", "GBP", "JPY", "KZT"]
    var topGainers: [CurrencyData] {
        currencyData.sorted { $0.changePercent > $1.changePercent }.prefix(3).map { $0 }
    }

    var topLosers: [CurrencyData] {
        currencyData.sorted { $0.changePercent < $1.changePercent }.prefix(3).map { $0 }
    }

    struct CurrencyData: Identifiable {
        let id = UUID()
        let flag: String
        let currency: String
        let rate: Double
        let change: Double
        let changePercent: Double
        let history: [(rate: Double, date: Date)]
    }

    @MainActor
    func fetchLatestRates(context: NSManagedObjectContext) {
        isLoading = true
        error = nil
        
        let url = "https://v6.exchangerate-api.com/v6/\(apiKey)/latest/\(baseCurrency)"
        
        AF.request(url).responseDecodable(of: ExchangeRatesResponse.self) { [weak self] response in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                
                switch response.result {
                case .success(let data):
                    self.processRealRates(data.conversion_rates, context: context)
                case .failure(let error):
                    self.error = error
                    print("Error fetching rates: \(error)")
                    self.loadSampleData(context: context)
                }
            }
        }
    }
    private func fetchHistory(for currencyCode: String, in context: NSManagedObjectContext) -> [CurrencyHistory] {
        let request: NSFetchRequest<CurrencyHistory> = CurrencyHistory.fetchRequest()
        request.predicate = NSPredicate(format: "currencyCode == %@", currencyCode)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CurrencyHistory.timestamp, ascending: true)]
        request.fetchLimit = 30 // 🔧 Ограничение последних 30 точек

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch history for \(currencyCode): \(error)")
            return []
        }
    }


    private func calculateChange(currentRate: Double, history: [CurrencyHistory]) -> Double {
        guard let previous = history.dropLast().last?.rate else {
            return 0.0
        }
        return currentRate - previous
    }

    
    private func processRealRates(_ rates: [String: Double], context: NSManagedObjectContext) {
        var newData: [CurrencyData] = []
        let now = Date()
        let currencyFlags = [
            "USD": "🇺🇸", "EUR": "🇪🇺", "CNY": "🇨🇳",
            "GBP": "🇬🇧", "JPY": "🇯🇵", "KZT": "🇰🇿"
        ]
        
        for currencyCode in targetCurrencies {
            guard let rawRate = rates[currencyCode], let flag = currencyFlags[currencyCode] else { continue }
            
            let rate = 1.0 / rawRate
            var history = fetchHistory(for: currencyCode, in: context)
            
            let shouldAddNewEntry = history.last.map {
                now.timeIntervalSince($0.timestamp ?? now) > 60
            } ?? true
            
            if shouldAddNewEntry {
                let historyEntity = CurrencyHistory(context: context)
                historyEntity.currencyCode = currencyCode
                historyEntity.rate = rate
                historyEntity.timestamp = now
                history.append(historyEntity)
            }

            let change = calculateChange(currentRate: rate, history: history)
            let previousRate = history.dropLast().last?.rate ?? rate
            let percentChange = previousRate != 0 ? (change / previousRate) * 100 : 0
            
            let historyTuples = history.map { ($0.rate, $0.timestamp ?? Date()) }

            newData.append(CurrencyData(
                flag: flag,
                currency: currencyCode,
                rate: rate,
                change: change,
                changePercent: percentChange,
                history: historyTuples
            ))
        }

        do {
            try context.save()
            if newData.map(\.rate) != currencyData.map(\.rate) {
                currencyData = newData
            }
        } catch {
            self.error = error
            print("Error saving context: \(error)")
        }
    }

    
    // Заглушка с тестовыми данными
    private func loadSampleData(context: NSManagedObjectContext) {
        let sampleRates: [String: Double] = [
            "USD": 0.011,  // 1 RUB = 0.011 USD
            "EUR": 0.010,   // 1 RUB = 0.010 EUR
            "CNY": 0.080,   // 1 RUB = 0.080 CNY
            "GBP": 0.0085,  // 1 RUB = 0.0085 GBP
            "JPY": 1.50,     // 1 RUB = 1.50 JPY
            "KZT": 5.20      // 1 RUB = 5.20 KZT
        ]
        
        processRealRates(sampleRates, context: context)
    }
    
    // Остальные методы остаются без изменений...
}

struct ExchangeRatesResponse: Decodable {
    let conversion_rates: [String: Double]
}


// MARK: - Helper Views
struct ErrorView: View {
    let error: Error
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text("Ошибка загрузки данных")
                .font(.headline)
            Text(error.localizedDescription)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .padding()
    }
}

struct CurrencyCardView: View {
    let currency: CurrencyService.CurrencyData
    @State private var selectedPointIndex: Int? = nil
    @State private var isSelected: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(currency.flag) \(currency.currency)")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()

                VStack(alignment: .trailing) {
                    Text(String(format: "%.2f ₽", currency.rate))
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(String(format: "%@%.2f%%",
                                currency.change >= 0 ? "+" : "",
                                currency.change))
                        .font(.caption)
                        .foregroundColor(currency.change >= 0 ? .green : .red)
                }
            }

            InteractiveLineChart(
                values: currency.history,
                selectedIndex: $selectedPointIndex,
                isSelected: $isSelected
            )
            .frame(height: 100)

            if let index = selectedPointIndex, isSelected, index < currency.history.count {
                let selected = currency.history[index]
                let current = selected.rate
                let previous = index > 0 ? currency.history[index - 1].rate : selected.rate
                let change = current - previous
                let percentChange = previous != 0 ? (change / previous) * 100 : 0

                VStack(alignment: .leading, spacing: 2) {
                    Text("Курс: \(String(format: "%.2f ₽", current))")
                        .font(.caption)
                        .foregroundColor(.white)
                    Text("Время: \(selected.date.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(String(format: "%@%.2f ₽ (%@%.2f%%)",
                                change >= 0 ? "+" : "",
                                change,
                                change >= 0 ? "+" : "",
                                percentChange))
                        .font(.caption2)
                        .foregroundColor(change >= 0 ? .green : .red)
                }
            }
            
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct InteractiveLineChart: View {
    let values: [(rate: Double, date: Date)]
    @Binding var selectedIndex: Int?
    @Binding var isSelected: Bool

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let maxValue = values.map { $0.rate }.max() ?? 1
            let minValue = values.map { $0.rate }.min() ?? 0
            let range = maxValue - minValue

            let points: [CGPoint] = values.enumerated().map { index, value in
                let x = CGFloat(index) / CGFloat(values.count - 1) * width
                let y = range > 0 ? height - CGFloat((value.rate - minValue) / range) * height : height / 2
                return CGPoint(x: x, y: y)
            }

            ZStack {
                if points.count > 1 {
                    Path { path in
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(Color.blue, lineWidth: 2)

                    if let index = selectedIndex, isSelected, index < points.count {
                        let selectedPoint = points[index]
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                            .position(selectedPoint)
                    }
                }
            }
            .contentShape(Rectangle()) // позволяет детектировать касания по всей области
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let x = value.location.x
                        let index = Int((x / width) * CGFloat(values.count - 1))
                        if index >= 0 && index < values.count {
                            selectedIndex = index
                            isSelected = true
                        }
                    }
                    .onEnded { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isSelected = false
                        }
                    }
            )
        }
    }
}

struct TopCurrenciesView: View {
    let title: String
    let currencies: [CurrencyService.CurrencyData]
    let gradientColors: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(currencies) { currency in
                HStack {
                    Text("\(currency.flag) \(currency.currency)")
                        .foregroundColor(.white)
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(String(format: "%.2f", currency.rate)) ₽")
                            .foregroundColor(.white)
                        Text("\(String(format: "%.2f", currency.rate - currency.change)) ₽ 24ч")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(String(format: "%@%.2f₽ (%@%.2f%%)",
                                   currency.change >= 0 ? "+" : "",
                                   currency.change,
                                   currency.change >= 0 ? "+" : "",
                                   (currency.change / (currency.rate - currency.change)) * 100))
                            .font(.caption)
                            .foregroundColor(currency.change >= 0 ? .green : .red)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(14)
    }
}
