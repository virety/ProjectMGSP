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
                        case 0: DepositCalculatorView()
                        case 1: CreditCalculatorView()
                        case 2: MortgageCalculatorView()
                        default: EmptyView()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    // Кнопка оформления
                    Button(action: {}) {
                        Text(getButtonText())
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(getButtonGradient())
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
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

// MARK: - Калькулятор ипотеки
struct MortgageCalculatorView: View {
    @State private var cost: String = ""
    @State private var firstPayment: String = ""
    @State private var years: String = ""
    
    @State private var monthlyPayment: Double = 0
    @State private var totalAmount: Double = 0
    @State private var overpayment: Double = 0
    @State private var showResult: Bool = false
    @State private var errorMessage: String? = nil
    @State private var centralBankRate: Double = 16.0
    @State private var isLoadingRate: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Стоимость жилья
            VStack(alignment: .leading, spacing: 4) {
                Text("Стоимость жилья")
                    .foregroundColor(.white)
                    .font(.subheadline)
                
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundColor(.purple)
                        .frame(width: 20)
                    
                    TextField("0 ₽", text: $cost)
                        .keyboardType(.decimalPad)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1))
                        .foregroundColor(.white)
                        .onChange(of: cost) { newValue in
                            cost = formatCurrencyInput(newValue)
                            validateInputs()
                            calculatePayment()
                        }
                }
            }
            
            // Первоначальный взнос
            VStack(alignment: .leading, spacing: 4) {
                Text("Первоначальный взнос")
                    .foregroundColor(.white)
                    .font(.subheadline)
                
                HStack {
                    Image(systemName: "rublesign.circle.fill")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    TextField("0 ₽", text: $firstPayment)
                        .keyboardType(.decimalPad)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1))
                        .foregroundColor(.white)
                        .onChange(of: firstPayment) { newValue in
                            firstPayment = formatCurrencyInput(newValue)
                            validateInputs()
                            calculatePayment()
                        }
                }
            }
            
            // Срок (в годах)
            VStack(alignment: .leading, spacing: 4) {
                Text("Срок (в годах)")
                    .foregroundColor(.white)
                    .font(.subheadline)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.green)
                        .frame(width: 20)
                    
                    TextField("0", text: $years)
                        .keyboardType(.numberPad)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1))
                        .foregroundColor(.white)
                        .onChange(of: years) { newValue in
                            years = filterDigits(newValue)
                            validateInputs()
                            calculatePayment()
                        }
                }
            }
            
            // Сообщение об ошибке
            if let error = errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
            
            // Всплывающее окно с результатами
            if showResult {
                VStack(spacing: 8) {
                    HStack {
                        Text("Ежемесячный платёж:")
                        Spacer()
                        Text("\(monthlyPayment.formattedCurrency()) ₽").bold()
                    }
                    
                    HStack {
                        Text("Общая сумма:")
                        Spacer()
                        Text("\(totalAmount.formattedCurrency()) ₽").bold()
                    }
                    
                    HStack {
                        Text("Переплата:")
                        Spacer()
                        Text("\(overpayment.formattedCurrency()) ₽").bold()
                    }
                    
                    HStack {
                        Text("Ставка ЦБ:")
                        Spacer()
                        Text("\(centralBankRate, specifier: "%.2f")%").bold()
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeInOut(duration: 0.3), value: showResult)
            } else {
                Text("Введите данные для расчёта ипотеки")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
            loadCentralBankRate()
        }
    }
    
    private func loadCentralBankRate() {
        isLoadingRate = true
        CentralBankService.shared.fetchKeyRate { rate in
            DispatchQueue.main.async {
                if let rate = rate {
                    self.centralBankRate = rate
                } else {
                    print("Не удалось загрузить ставку ЦБ — используется значение по умолчанию")
                }
                self.isLoadingRate = false
                self.validateInputs()
                self.calculatePayment()
            }
        }
    }

    private func validateInputs() {
        let cleanCost = cost.replacingOccurrences(of: " ", with: "")
        let cleanFirstPayment = firstPayment.replacingOccurrences(of: " ", with: "")
        let costValue = Double(cleanCost) ?? 0
        let firstPaymentValue = Double(cleanFirstPayment) ?? 0
        let yearsValue = Int(years) ?? 0
        
        errorMessage = nil
        
        if cleanCost.isEmpty || cleanFirstPayment.isEmpty || years.isEmpty {
            errorMessage = "Заполните все поля"
            return
        }
        
        if costValue < 100000 {
            errorMessage = "Минимальная стоимость жилья - 100 000 ₽"
            return
        }
        
        if firstPaymentValue < costValue * 0.1 {
            errorMessage = "Первоначальный взнос должен быть не менее 10% от стоимости"
            return
        }
        
        if firstPaymentValue >= costValue {
            errorMessage = "Первоначальный взнос не может превышать стоимость жилья"
            return
        }
        
        if yearsValue < 1 {
            errorMessage = "Минимальный срок кредита - 1 год"
            return
        }
        
        if yearsValue > 30 {
            errorMessage = "Максимальный срок кредита - 30 лет"
            return
        }
    }
    
    private func calculatePayment() {
        let cleanCost = cost.replacingOccurrences(of: " ", with: "")
        let cleanFirstPayment = firstPayment.replacingOccurrences(of: " ", with: "")
        let costValue = Double(cleanCost) ?? 0
        let firstPaymentValue = Double(cleanFirstPayment) ?? 0
        let yearsValue = Double(years) ?? 0
        
        guard costValue >= 100000,
              firstPaymentValue >= costValue * 0.1,
              firstPaymentValue < costValue,
              yearsValue >= 1,
              yearsValue <= 30,
              errorMessage == nil else {
            showResult = false
            return
        }
        
        let S = costValue - firstPaymentValue
        let p = centralBankRate / 100 / 12
        let n = yearsValue * 12
        
        if p == 0 || n == 0 {
            monthlyPayment = S / max(n, 1)
            totalAmount = S
            overpayment = 0
        } else {
            monthlyPayment = S * p * pow(1 + p, n) / (pow(1 + p, n) - 1)
            totalAmount = monthlyPayment * n
            overpayment = totalAmount - S
        }
        
        showResult = true
    }
    
    private func formatCurrencyInput(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        guard let number = Double(digits) else { return "" }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: number)) ?? ""
    }
    
    private func filterDigits(_ input: String) -> String {
        input.filter { $0.isNumber }
    }
}

// MARK: - Калькулятор кредита
struct CreditCalculatorView: View {
    @State private var amount: String = ""
    @State private var months: String = ""
    @State private var monthlyPayment: Double = 0
    @State private var overpayment: Double = 0
    @State private var totalAmount: Double = 0
    @State private var baseRate: Double = 16.0
    @State private var showResult: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            // Сумма кредита
            VStack(alignment: .leading, spacing: 4) {
                Text("Сумма кредита")
                    .foregroundColor(.white)
                    .font(.subheadline)
                
                HStack {
                    Image(systemName: "rublesign.circle.fill")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    TextField("0 ₽", text: $amount)
                        .keyboardType(.decimalPad)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1))
                        .foregroundColor(.white)
                        .onChange(of: amount) { newValue in
                            amount = formatCurrencyInput(newValue)
                            validateInputs()
                            calculatePayment()
                        }
                }
            }
            
            // Срок (в месяцах)
            VStack(alignment: .leading, spacing: 4) {
                Text("Срок (в месяцах)")
                    .foregroundColor(.white)
                    .font(.subheadline)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.green)
                        .frame(width: 20)
                    
                    TextField("0", text: $months)
                        .keyboardType(.numberPad)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1))
                        .foregroundColor(.white)
                        .onChange(of: months) { newValue in
                            months = filterDigits(newValue)
                            validateInputs()
                            calculatePayment()
                        }
                }
            }
            
            // Сообщение об ошибке
            if let error = errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
            
            // Всплывающее окно с результатами
            if showResult {
                VStack(spacing: 8) {
                    HStack {
                        Text("Ежемесячный платёж:")
                        Spacer()
                        Text("\(monthlyPayment.formattedCurrency()) ₽").bold()
                    }
                    
                    HStack {
                        Text("Общая сумма:")
                        Spacer()
                        Text("\(totalAmount.formattedCurrency()) ₽").bold()
                    }
                    
                    HStack {
                        Text("Переплата:")
                        Spacer()
                        Text("\(overpayment.formattedCurrency()) ₽").bold()
                    }
                    
                    HStack {
                        Text("Ставка:")
                        Spacer()
                        Text("\(baseRate, specifier: "%.2f")%").bold()
                            .foregroundColor(baseRate < 16.0 ? .green : .white)
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeInOut(duration: 0.3), value: showResult)
            } else {
                Text("Введите корректные данные для расчёта")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func validateInputs() {
        let cleanAmount = amount.replacingOccurrences(of: " ", with: "")
        let amountValue = Double(cleanAmount) ?? 0
        let monthsValue = Int(months) ?? 0
        
        errorMessage = nil
        
        if cleanAmount.isEmpty || months.isEmpty {
            errorMessage = "Заполните все поля"
            return
        }
        
        if amountValue < 10000 {
            errorMessage = "Минимальная сумма кредита - 10 000 ₽"
            return
        }
        
        if amountValue > 500000 {
            errorMessage = "Максимальная сумма кредита - 500 000 ₽"
            return
        }
        
        if monthsValue < 1 {
            errorMessage = "Минимальный срок - 1 месяц"
            return
        }
        
        if amountValue <= 30000 && monthsValue > 12 {
            errorMessage = "Для сумм до 30 000 ₽ максимальный срок - 12 месяцев"
            return
        }
        
        if amountValue <= 300000 && monthsValue > 36 {
            errorMessage = "Для сумм до 300 000 ₽ максимальный срок - 3 года (36 месяцев)"
            return
        }
        
        if monthsValue > 60 {
            errorMessage = "Максимальный срок кредита - 5 лет (60 месяцев)"
            return
        }
    }
    
    private func calculatePayment() {
        let cleanAmount = amount.replacingOccurrences(of: " ", with: "")
        let amountValue = Double(cleanAmount) ?? 0
        let monthsValue = Double(months) ?? 0
        
        guard amountValue >= 10000, amountValue <= 750000,
              monthsValue >= 1, errorMessage == nil else {
            showResult = false
            return
        }
        
        // Определение ставки
        if amountValue <= 30000 && monthsValue <= 12 {
            baseRate = 6.0 // Молодежный кредит
        } else if amountValue <= 300000 && monthsValue <= 36 {
            baseRate = 12.0 // Средний кредит
        } else {
            baseRate = 16.0 // Стандартный кредит
        }
        
        let monthlyRate = baseRate / 100 / 12
        let payment = amountValue * monthlyRate * pow(1 + monthlyRate, monthsValue) / (pow(1 + monthlyRate, monthsValue) - 1)
        
        monthlyPayment = payment
        totalAmount = payment * monthsValue
        overpayment = totalAmount - amountValue
        showResult = true
    }
    
    private func formatCurrencyInput(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        guard let number = Double(digits) else { return "" }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: number)) ?? ""
    }
    
    private func filterDigits(_ input: String) -> String {
        input.filter { $0.isNumber }
    }
}

// MARK: - Калькулятор вклада
struct DepositCalculatorView: View {
    @State private var amount: String = ""
    @State private var months: String = ""
    @State private var totalAmount: Double = 0
    @State private var income: Double = 0
    @State private var baseRate: Double = 16.0
    @State private var showResult: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            // Сумма вклада
            VStack(alignment: .leading, spacing: 4) {
                Text("Сумма вклада")
                    .foregroundColor(.white)
                    .font(.subheadline)
                
                HStack {
                    Image(systemName: "banknote.fill")
                        .foregroundColor(.green)
                        .frame(width: 20)
                    
                    TextField("0 ₽", text: $amount)
                        .keyboardType(.numberPad)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1))
                        .foregroundColor(.white)
                        .onChange(of: amount) { newValue in
                            amount = formatCurrencyInput(newValue)
                            validateInputs()
                            calculateTotal()
                        }
                }
            }
            
            // Срок (в месяцах)
            VStack(alignment: .leading, spacing: 4) {
                Text("Срок (в месяцах)")
                    .foregroundColor(.white)
                    .font(.subheadline)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    TextField("0", text: $months)
                        .keyboardType(.numberPad)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1))
                        .foregroundColor(.white)
                        .onChange(of: months) { newValue in
                            months = filterDigits(newValue)
                            validateInputs()
                            calculateTotal()
                        }
                }
            }
            
            // Сообщение об ошибке
            if let error = errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
            
            // Всплывающее окно с результатами
            if showResult {
                VStack(spacing: 8) {
                    HStack {
                        Text("Сумма к концу срока:")
                        Spacer()
                        Text("\(totalAmount.formattedCurrency()) ₽").bold()
                    }
                    
                    HStack {
                        Text("Доход:")
                        Spacer()
                        Text("\(income.formattedCurrency()) ₽").bold()
                    }
                    
                    HStack {
                        Text("Ставка:")
                        Spacer()
                        Text("\(baseRate, specifier: "%.2f")%").bold()
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeInOut(duration: 0.3), value: showResult)
            } else {
                Text("Введите корректные данные для расчёта")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func validateInputs() {
        let cleanAmount = amount.replacingOccurrences(of: " ", with: "")
        let amountValue = Double(cleanAmount) ?? 0
        let monthsValue = Int(months) ?? 0
        
        errorMessage = nil
        
        if cleanAmount.isEmpty || months.isEmpty {
            errorMessage = "Заполните все поля"
            return
        }
        
        if amountValue < 10000 {
            errorMessage = "Минимальная сумма вклада - 10 000 ₽"
            return
        }
        
        if monthsValue < 1 {
            errorMessage = "Минимальный срок - 1 месяц"
            return
        }
        
        if monthsValue > 60 {
            errorMessage = "Максимальный срок - 5 лет (60 месяцев)"
            return
        }
    }
    
    private func calculateTotal() {
        let cleanAmount = amount.replacingOccurrences(of: " ", with: "")
        let rawAmount = Double(cleanAmount) ?? 0
        let rawMonths = Double(months) ?? 0
        
        guard rawAmount >= 10000, rawMonths >= 1, errorMessage == nil else {
            totalAmount = 0
            income = 0
            showResult = false
            return
        }
        
        // Определение ставки
        if rawAmount <= 30000 && rawMonths <= 12 {
            baseRate = 10.0 // Короткий вклад
        } else {
            baseRate = 16.0 // Долгосрочный вклад
        }
        
        let r = baseRate / 100 / 12
        let n = rawMonths
        totalAmount = rawAmount * pow(1 + r, n)
        income = totalAmount - rawAmount
        showResult = true
    }
    
    private func formatCurrencyInput(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        guard let number = Double(digits) else { return "" }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: number)) ?? ""
    }
    
    private func filterDigits(_ input: String) -> String {
        input.filter { $0.isNumber }
    }
}
