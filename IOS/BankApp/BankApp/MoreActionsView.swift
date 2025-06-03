//
//  MoreActionsView.swift
//  BankApp
//
//  Created by Вадим Семибратов on 03.06.2025.
//
import SwiftUI

struct CurrencyRate: Identifiable {
    let id = UUID()
    let flag: String
    let currency: String
    let rate: Double
    let change: Double
    let history: [Double]
}

struct MoreActionsView: View {
    @State private var selectedCurrencyId: UUID? = nil
    @State private var selectedPointIndex: Int? = nil
    
    private let currencies: [CurrencyRate] = [
        CurrencyRate(flag: "🇺🇸", currency: "USD", rate: 89.25, change: -0.15, history: [88.7, 88.9, 89.0, 89.3, 89.25, 89.1, 89.4, 89.25]),
        CurrencyRate(flag: "🇪🇺", currency: "EUR", rate: 97.10, change: 0.42, history: [96.3, 96.5, 96.8, 97.0, 97.10, 96.9, 97.2, 97.1]),
        CurrencyRate(flag: "🇨🇳", currency: "CNY", rate: 12.50, change: -0.02, history: [12.6, 12.55, 12.52, 12.50, 12.45, 12.48, 12.5]),
        CurrencyRate(flag: "🇬🇧", currency: "GBP", rate: 113.75, change: 0.55, history: [112.2, 112.8, 113.0, 113.75, 113.5, 113.6, 113.75]),
        CurrencyRate(flag: "🇯🇵", currency: "JPY", rate: 0.60, change: -0.01, history: [0.62, 0.61, 0.605, 0.60, 0.595, 0.598, 0.6]),
        CurrencyRate(flag: "🇰🇿", currency: "KZT", rate: 0.19, change: 0.003, history: [0.185, 0.187, 0.188, 0.19, 0.189, 0.191, 0.19])
    ]
    
    var topGainers: [CurrencyRate] {
        currencies.sorted { $0.change > $1.change }.prefix(3).map { $0 }
    }

    var topLosers: [CurrencyRate] {
        currencies.sorted { $0.change < $1.change }.prefix(3).map { $0 }
    }

    var body: some View {
        ZStack {
            // Градиентный фон
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.06, green: 0.04, blue: 0.15),
                    Color(red: 0.15, green: 0.08, blue: 0.35),
                    Color(red: 0.25, green: 0.13, blue: 0.45)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Курсы валют")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal)

                    ForEach(currencies) { currency in
                        CurrencyCardView(
                            currency: currency,
                            isSelected: selectedCurrencyId == currency.id,
                            selectedPointIndex: selectedPointIndex,
                            onSelect: { index in
                                selectedCurrencyId = currency.id
                                selectedPointIndex = index
                            },
                            onDeselect: {
                                selectedCurrencyId = nil
                                selectedPointIndex = nil
                            }
                        )
                    }

                    // Топ ↑
                    TopCurrenciesView(
                        title: "📈 Топ рост",
                        currencies: topGainers,
                        gradientColors: [Color.green.opacity(0.4)]
                    )
                    .padding(.horizontal)

                    // Топ ↓
                    TopCurrenciesView(
                        title: "📉 Топ падение",
                        currencies: topLosers,
                        gradientColors: [Color.red.opacity(0.4)]
                    )
                    .padding(.horizontal)
                }
                .padding(.top)
            }
        }
        .navigationTitle("Другое")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CurrencyCardView: View {
    let currency: CurrencyRate
    let isSelected: Bool
    let selectedPointIndex: Int?
    let onSelect: (Int) -> Void
    let onDeselect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(currency.flag) \(currency.currency)")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                
                VStack(alignment: .trailing) {
                    if let index = selectedPointIndex, isSelected, index < currency.history.count {
                        Text(String(format: "%.2f ₽", currency.history[index]))
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        
                        let change = currency.history[index] - (index > 0 ? currency.history[index-1] : currency.history[index])
                        Text(String(format: "%@%.2f ₽ (%@%.2f%%)",
                                      change >= 0 ? "+" : "",
                                      change,
                                      change >= 0 ? "+" : "",
                                      (change / (currency.history[index] - change)) * 100))
                            .font(.caption2)
                            .foregroundColor(change >= 0 ? .green : .red)
                    } else {
                        Text(String(format: "%.2f ₽", currency.rate))
                            .foregroundColor(.white)
                        
                        Text(String(format: "%@%.2f ₽ (%@%.2f%%)",
                                   currency.change >= 0 ? "+" : "",
                                   currency.change,
                                   currency.change >= 0 ? "+" : "",
                                   (currency.change / (currency.rate - currency.change)) * 100))
                            .font(.caption2)
                            .foregroundColor(currency.change >= 0 ? .green : .red)
                    }
                }
            }
            
            InteractiveLineChart(
                values: currency.history,
                currentValue: currency.rate,
                change: currency.change,
                isSelected: isSelected,
                selectedPointIndex: selectedPointIndex,
                onSelect: onSelect,
                onDeselect: onDeselect
            )
            .frame(height: 100)
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct InteractiveLineChart: View {
    let values: [Double]
    let currentValue: Double
    let change: Double
    let isSelected: Bool
    let selectedPointIndex: Int?
    let onSelect: (Int) -> Void
    let onDeselect: () -> Void
    
    private var minY: Double {
        (values.min() ?? 0) * 0.98
    }
    
    private var maxY: Double {
        (values.max() ?? 1) * 1.02
    }
    
    private var points: [CGPoint] {
        let width = UIScreen.main.bounds.width - 60
        let height: CGFloat = 80
        
        return values.enumerated().map { index, value in
            CGPoint(
                x: CGFloat(index) * (width / CGFloat(values.count - 1)),
                y: height - CGFloat((value - minY) / (maxY - minY)) * height
            )
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Фон графика
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                
                // Линия графика
                Path { path in
                    guard !points.isEmpty else { return }
                    path.move(to: points[0])
                    
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(
                    change >= 0 ? Color.green : Color.red,
                    style: StrokeStyle(
                        lineWidth: 2,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                
                // Точки на графике (только при выборе)
                if isSelected {
                    ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                        Circle()
                            .fill(index == selectedPointIndex ? Color.white : Color.gray)
                            .frame(width: 6, height: 6)
                            .position(point)
                    }
                }
                
                // Индикатор выбранной точки
                if isSelected, let index = selectedPointIndex, index < points.count {
                    VStack(spacing: 4) {
                        Text(String(format: "%.2f", values[index]))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(change >= 0 ? Color.green : Color.red, lineWidth: 2)
                            )
                    }
                    .position(x: points[index].x, y: points[index].y - 20)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let xPosition = value.location.x
                        let step = geometry.size.width / CGFloat(values.count - 1)
                        let index = min(max(Int((xPosition / step).rounded()), 0), values.count - 1)
                        onSelect(index)
                    }
                    .onEnded { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            onDeselect()
                        }
                    }
            )
        }
    }
}

struct TopCurrenciesView: View {
    let title: String
    let currencies: [CurrencyRate]
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
