import SwiftUI
import CoreData

struct MortgageCalculatorView: View {
    @State private var cost: String = ""
    @State private var firstPayment: String = ""
    @State private var termYears: String = ""

    @State private var monthlyPayment: Double = 0
    @State private var totalPayment: Double = 0
    @State private var overpayment: Double = 0
    @State private var loanAmount: Double = 0

    @State private var showResult: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showSaveConfirmation: Bool = false
    @State private var userBalance: Double = 0
    @State private var centralBankRate: Double = 16.0
    @State private var isLoadingRate = false

    var body: some View {
        VStack(spacing: 16) {
            Group {
                mortgageInputField(title: "Стоимость недвижимости", symbol: "house.fill", text: $cost)
                    .onChange(of: cost) { newValue in
                        cost = formatCurrencyInput(newValue)
                        validateInputs()
                        calculateMortgage()
                    }

                mortgageInputField(title: "Первоначальный взнос", symbol: "banknote.fill", text: $firstPayment)
                    .onChange(of: firstPayment) { newValue in
                        firstPayment = formatCurrencyInput(newValue)
                        validateInputs()
                        calculateMortgage()
                        depositInitialPaymentToBalance()
                    }

                mortgageInputField(title: "Срок (в годах)", symbol: "calendar", text: $termYears)
                    .onChange(of: termYears) { newValue in
                        termYears = filterDigits(newValue)
                        validateInputs()
                        calculateMortgage()
                    }
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            if showResult {
                VStack(spacing: 8) {
                    resultRow("Ежемесячный платёж:", monthlyPayment)
                    resultRow("Общая сумма:", totalPayment)
                    resultRow("Переплата:", overpayment)
                    resultRow("Ставка ЦБ:", centralBankRate, isPercent: true)

                    Button("Оформить ипотеку") {
                        saveMortgage()
                        withdrawMortgageAmountFromBalance()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                    .foregroundColor(.white)
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
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
            updateUserBalance()
            loadCentralBankRate()
        }
        .alert(isPresented: $showSaveConfirmation) {
            Alert(title: Text("Ипотека оформлена"),
                  message: Text("Данные успешно сохранены."),
                  dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Core Logic

    private func saveMortgage() {
        let costValue = Double(cost.replacingOccurrences(of: " ", with: "")) ?? 0
        let years = Int(termYears) ?? 0

        CoreDataManager.shared.saveMortgage(
            amount: loanAmount,
            termYears: years,
            rate: centralBankRate,
            monthly: monthlyPayment,
            total: totalPayment,
            overpay: overpayment
        )

        showSaveConfirmation = true
    }

    private func calculateMortgage() {
        let costValue = Double(cost.replacingOccurrences(of: " ", with: "")) ?? 0
        let firstPaymentValue = Double(firstPayment.replacingOccurrences(of: " ", with: "")) ?? 0
        loanAmount = costValue - firstPaymentValue
        let years = Double(termYears) ?? 0
        let rate = centralBankRate

        guard loanAmount > 0, years > 0, rate > 0 else {
            showResult = false
            return
        }

        let months = years * 12
        let monthlyRate = rate / 100 / 12
        let payment = loanAmount * monthlyRate * pow(1 + monthlyRate, months) / (pow(1 + monthlyRate, months) - 1)

        monthlyPayment = payment
        totalPayment = payment * months
        overpayment = totalPayment - loanAmount
        showResult = true
    }

    private func validateInputs() {
        errorMessage = nil
        if cost.isEmpty || firstPayment.isEmpty || termYears.isEmpty {
            errorMessage = "Заполните все поля"
        }
    }

    private func depositInitialPaymentToBalance() {
        let amount = Double(firstPayment.replacingOccurrences(of: " ", with: "")) ?? 0
        guard amount >= 1000 else { return }

        if let user = CoreDataManager.shared.fetchUser() {
            user.balance += amount
            CoreDataManager.shared.saveContext()
            updateUserBalance()
        }
    }

    private func withdrawMortgageAmountFromBalance() {
        if let user = CoreDataManager.shared.fetchUser() {
            if user.balance >= totalPayment {
                user.balance -= totalPayment
                CoreDataManager.shared.saveContext()
                updateUserBalance()
            } else {
                errorMessage = "Недостаточно средств для ипотеки"
            }
        }
    }

    private func updateUserBalance() {
        if let user = CoreDataManager.shared.fetchUser() {
            userBalance = user.balance
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
                isLoadingRate = false
                calculateMortgage()
            }
        }
    }

    // MARK: - UI Helpers

    private func mortgageInputField(title: String, symbol: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .foregroundColor(.white)
                .font(.subheadline)

            HStack {
                Image(systemName: symbol)
                    .foregroundColor(.blue)
                    .frame(width: 20)

                TextField("0", text: text)
                    .keyboardType(.decimalPad)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1))
                    .foregroundColor(.white)
            }
        }
    }

    private func resultRow(_ label: String, _ value: Double, isPercent: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(isPercent ? "\(value, specifier: "%.2f")%" : "\(value.formattedCurrency()) ₽").bold()
        }
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

