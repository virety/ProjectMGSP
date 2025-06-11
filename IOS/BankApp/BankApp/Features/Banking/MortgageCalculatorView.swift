import SwiftUI
import CoreData

struct MortgageCalculatorView: View {
    @State private var cost: String = ""
    @State private var firstPayment: String = ""
    @State private var termYears: String = ""
    @State private var creditScore: Int = 0
    @State private var maxMortgageAmount: Double = 0
    @State private var canTakeMortgage: Bool = false

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
            // Credit Score Info
            VStack(alignment: .leading, spacing: 8) {
                Text("Кредитный рейтинг: \(creditScore)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Максимальная сумма ипотеки: \(maxMortgageAmount.formattedCurrency()) ₽")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                if !canTakeMortgage {
                    Text("⚠️ В данный момент вы не можете взять ипотеку")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)

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
                    resultRow("Ставка:", getAdjustedRate(), isPercent: true)

                    Button("Оформить ипотеку") {
                        saveMortgage()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(canTakeMortgage ? Color.green : Color.gray)
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .disabled(!canTakeMortgage)
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
            updateCreditInfo()
        }
        .alert(isPresented: $showSaveConfirmation) {
            Alert(title: Text("Ипотека оформлена"),
                  message: Text("Данные успешно сохранены."),
                  dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Core Logic

    private func updateCreditInfo() {
        if let user = CoreDataManager.shared.fetchUser() {
            creditScore = CreditHistoryManager.shared.calculateCreditScore(for: user)
            maxMortgageAmount = CreditHistoryManager.shared.getMaxMortgageAmount(for: user)
            canTakeMortgage = CreditHistoryManager.shared.canTakeMortgage(for: user)
        }
    }

    private func getAdjustedRate() -> Double {
        // Adjust base rate based on credit score
        var adjustedRate = centralBankRate
        switch creditScore {
        case 900...1000:
            adjustedRate -= 3.0
        case 800...899:
            adjustedRate -= 2.0
        case 700...799:
            adjustedRate -= 1.0
        case 600...699:
            adjustedRate -= 0.5
        default:
            break
        }
        return max(adjustedRate, 6.0) // Minimum rate of 6%
    }

    private func saveMortgage() {
        guard canTakeMortgage else {
            errorMessage = "Вы не можете взять ипотеку в данный момент"
            return
        }

        let costValue = Double(cost.replacingOccurrences(of: " ", with: "")) ?? 0
        let years = Int(termYears) ?? 0

        if let currentUser = CoreDataManager.shared.fetchUser() {
            CoreDataManager.shared.saveMortgage(
                for: currentUser,
                amount: loanAmount,
                termYears: years,
                rate: getAdjustedRate(),
                monthly: monthlyPayment,
                total: totalPayment,
                overpay: overpayment
            )

            // Update user's balance
            currentUser.balance += loanAmount
            CoreDataManager.shared.saveContext()

        showSaveConfirmation = true
            updateCreditInfo()
            updateUserBalance()
        }
    }

    private func calculateMortgage() {
        let costValue = Double(cost.replacingOccurrences(of: " ", with: "")) ?? 0
        let firstPaymentValue = Double(firstPayment.replacingOccurrences(of: " ", with: "")) ?? 0
        loanAmount = costValue - firstPaymentValue
        let years = Double(termYears) ?? 0
        let rate = getAdjustedRate()

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
            return
    }

        let costValue = Double(cost.replacingOccurrences(of: " ", with: "")) ?? 0
        let firstPaymentValue = Double(firstPayment.replacingOccurrences(of: " ", with: "")) ?? 0
        let loanValue = costValue - firstPaymentValue
        
        if loanValue > maxMortgageAmount {
            errorMessage = "Сумма ипотеки превышает максимально доступную"
            return
        }
        
        if firstPaymentValue < costValue * 0.15 {
            errorMessage = "Первоначальный взнос должен быть не менее 15%"
            return
        }
        
        if !canTakeMortgage {
            errorMessage = "В данный момент вы не можете взять ипотеку"
            return
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

