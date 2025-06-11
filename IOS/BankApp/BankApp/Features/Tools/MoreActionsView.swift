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
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
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
        
        let url = "https://v6.exchangerate-api.com/v6/deacf4eb8c4f35e2bcda9bc8/latest/\(baseCurrency)"
        
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
struct InteractiveLineChart: View {
    let values: [(rate: Double, date: Date)]
    @Binding var selectedIndex: Int?
    @Binding var isSelected: Bool
    
    private let lineWidth: CGFloat = 3
    private let dotSize: CGFloat = 10
    private let shadowRadius: CGFloat = 10
    private let animationDuration: Double = 0.8
    
    private var normalizedValues: [Double] {
        guard !values.isEmpty else { return [] }
        let rates = values.map { $0.rate }
        let minRate = rates.min() ?? 0
        let maxRate = rates.max() ?? 1
        let range = maxRate - minRate
        
        // Усиливаем визуализацию малых изменений
        return rates.map { rate in
            let normalized = range > 0 ? (rate - minRate) / range : 0.5
            return pow(normalized, 0.7)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                // Градиент под линией
                if values.count > 1 {
                    Path { path in
                        for (index, value) in normalizedValues.enumerated() {
                            let x = CGFloat(index) / CGFloat(values.count - 1) * width
                            let y = height - CGFloat(value) * height
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        path.addLine(to: CGPoint(x: width, y: height))
                        path.addLine(to: CGPoint(x: 0, y: height))
                        path.closeSubpath()
                    }
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.05)]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                }
                
                // Основная линия графика
                if values.count > 1 {
                    Path { path in
                        for (index, value) in normalizedValues.enumerated() {
                            let x = CGFloat(index) / CGFloat(values.count - 1) * width
                            let y = height - CGFloat(value) * height
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .trim(from: 0, to: isSelected ? 1 : 0)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.cyan]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .shadow(color: Color.blue.opacity(0.5), radius: shadowRadius, x: 0, y: 5)
                    .animation(.easeInOut(duration: animationDuration), value: isSelected)
                    
                    // Дополнительная тонкая линия
                    Path { path in
                        for (index, value) in normalizedValues.enumerated() {
                            let x = CGFloat(index) / CGFloat(values.count - 1) * width
                            let y = height - CGFloat(value) * height
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        Color.white.opacity(0.8),
                        style: StrokeStyle(
                            lineWidth: 0.5,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                }
                
                // Точки на графике
                ForEach(Array(values.enumerated()), id: \.offset) { index, _ in
                    let x = CGFloat(index) / CGFloat(values.count - 1) * width
                    let y = height - CGFloat(normalizedValues[index]) * height
                    
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 3, height: 3)
                        .position(x: x, y: y)
                }
                
                // Выбранная точка
                if let index = selectedIndex, isSelected, index < values.count {
                    let x = CGFloat(index) / CGFloat(values.count - 1) * width
                    let y = height - CGFloat(normalizedValues[index]) * height
                    let selectedPoint = CGPoint(x: x, y: y)
                    
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white, Color.cyan]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: dotSize * 2, height: dotSize * 2)
                        .position(selectedPoint)
                        .opacity(isSelected ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3).repeatForever(), value: isSelected)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: dotSize, height: dotSize)
                        .position(selectedPoint)
                        .shadow(color: Color.blue, radius: 5, x: 0, y: 0)
                }
            }
            .drawingGroup()
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let x = value.location.x
                        let index = Int((x / width) * CGFloat(values.count - 1)).clamped(to: 0..<values.count)
                        selectedIndex = index
                        isSelected = true
                    }
                    .onEnded { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                isSelected = false
                            }
                        }
                    }
            )
        }
    }
}
// Вспомогательное расширение для ограничения диапазона
extension Int {
    func clamped(to range: Range<Int>) -> Int {
        let lower = Swift.max(self, range.lowerBound)
        return Swift.min(lower, range.upperBound - 1)
    }
}

// Обновленный CurrencyCardView для лучшего отображения
struct CurrencyCardView: View {
    let currency: CurrencyService.CurrencyData
    @State private var selectedPointIndex: Int? = nil
    @State private var isSelected: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(currency.flag) \(currency.currency)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(String(format: "%.2f ₽", currency.rate))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Image(systemName: currency.change >= 0 ? "arrow.up" : "arrow.down")
                        Text(String(format: "%@%.2f%%",
                                   currency.change >= 0 ? "+" : "",
                                   currency.changePercent))
                    }
                    .font(.caption)
                    .foregroundColor(currency.change >= 0 ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(currency.change >= 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .cornerRadius(4)
                }
            }
            
            InteractiveLineChart(
                values: currency.history,
                selectedIndex: $selectedPointIndex,
                isSelected: $isSelected
            )
            .frame(height: 120)
            .padding(.vertical, 4)
            
            if let index = selectedPointIndex, isSelected, index < currency.history.count {
                let selected = currency.history[index]
                let current = selected.rate
                let previous = index > 0 ? currency.history[index - 1].rate : selected.rate
                let change = current - previous
                let percentChange = previous != 0 ? (change / previous) * 100 : 0
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Курс:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(String(format: "%.2f ₽", current))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Изменение:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(String(format: "%@%.2f ₽ (%@%.2f%%)",
                                   change >= 0 ? "+" : "",
                                   change,
                                   change >= 0 ? "+" : "",
                                   percentChange))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(change >= 0 ? .green : .red)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Время:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(selected.date.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
        .animation(.spring(), value: isSelected)
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
