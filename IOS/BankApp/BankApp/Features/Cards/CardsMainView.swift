//
//  CardsMainView.swift
//  BankApp
//
//  Created by Вадим Семибратов on 03.06.2025.
//
import SwiftUI
import Foundation
import SwiftSoup

class CentralBankService {
    static let shared = CentralBankService()
    
    func fetchKeyRate(completion: @escaping (Double?) -> Void) {
        guard let url = URL(string: "https://www.cbr.ru/hd_base/KeyRate/") else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data,
                  let html = String(data: data, encoding: .utf8),
                  error == nil else {
                print("Ошибка загрузки HTML: \(error?.localizedDescription ?? "нет данных")")
                completion(nil)
                return
            }

            do {
                let doc = try SwiftSoup.parse(html)
                let table = try doc.select("table.data").first()
                if let firstRow = try table?.select("tr").dropFirst().first,
                   let rateCell = try firstRow.select("td").last() {
                    let rateString = try rateCell.text().replacingOccurrences(of: ",", with: ".")
                    let rate = Double(rateString)
                    completion(rate)
                } else {
                    completion(nil)
                }
            } catch {
                print("Ошибка парсинга HTML: \(error)")
                completion(nil)
            }
        }.resume()
    }
}




struct CardsMainView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedTab: MainTabView.Tab
    
    @State private var selectedOption = 0
    private let options = ["Вклады", "Кредиты", "Ипотека"]
    
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
            
            // Основной контент с прокруткой
            ScrollView {
                VStack(spacing: 0) {
                    // Шапка (фиксированная)
                    headerView()
                        .padding(.bottom, 12)
                    
                    // Переключатель вкладок
                    customSegmentedControl()
                        .padding(.bottom, 12)
                    
                    // Изображение продукта
                    Group {
                        switch selectedOption {
                        case 0:
                            Image("вклад1")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 240)
                        case 1:
                            Image("кредит")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 240)
                        case 2:
                            Image("ипотека")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 240)
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    // Калькулятор
                    Group {
                        switch selectedOption {
                        case 0:
                            AnyView(DepositCalculatorView())
                        case 1:
                            AnyView(CreditCalculatorView())
                        case 2:
                            AnyView(MortgageCalculatorView()) // <-- без параметров
                        default:
                            AnyView(EmptyView())
                        }
                    }

                    .padding(.horizontal)
                    .padding(.bottom, 16)


                }
                .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarHidden(true)
    }
    
    private func getButtonText() -> String {
        switch selectedOption {
        case 0: return "Оформить вклад"
        case 1: return "Оформить кредит"
        case 2: return "Оформить ипотеку"
        default: return "Оформить"
        }
    }
    
    private func getButtonGradient() -> LinearGradient {
        switch selectedOption {
        case 0: // Вклад - зеленый градиент
            return LinearGradient(
                colors: [Color.green.opacity(0.7), Color(red: 0, green: 0.6, blue: 0.3)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case 1: // Кредит - синий градиент
            return LinearGradient(
                colors: [Color.blue.opacity(0.7), Color(red: 0, green: 0.3, blue: 0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case 2: // Ипотека - фиолетовый градиент
            return LinearGradient(
                colors: [Color.purple.opacity(0.7), Color(red: 0.5, green: 0, blue: 0.5)],
                startPoint: .leading,
                endPoint: .trailing
            )
        default:
            return LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.blue],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private func headerView() -> some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .ignoresSafeArea(edges: .top)
                .frame(height: 56)

            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 18))
                Text("Финансовый помощник")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)

            HStack {
                Button(action: {
                    if presentationMode.wrappedValue.isPresented {
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        selectedTab = .home
                    }
                }) {
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

    private func customSegmentedControl() -> some View {
        HStack(spacing: 8) {
            ForEach(0..<options.count, id: \.self) { index in
                Button(action: {
                    selectedOption = index
                }) {
                    Text(options[index])
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedOption == index ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedOption == index {
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.purple.opacity(0.8),
                                            Color.blue.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                } else {
                                    Color.white.opacity(0.9)
                                }
                            }
                        )
                        .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Вспомогательные расширения
extension Double {
    func formattedCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = " "
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

func formatNumberInput(_ input: String) -> String {
    let digits = input.filter { $0.isNumber }
    guard let number = Int(digits) else { return input }

    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.groupingSeparator = " "
    formatter.locale = Locale(identifier: "ru_RU")
    return formatter.string(from: NSNumber(value: number)) ?? input
}

func cleanNumber(_ formatted: String) -> Double {
    return Double(formatted.filter { $0.isNumber }) ?? 0
}




