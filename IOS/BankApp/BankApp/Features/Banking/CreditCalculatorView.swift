import SwiftUI
import CoreData

struct CreditCalculatorView: View {
    @State private var amount: String = ""
    @State private var months: String = ""
    @State private var creditScore: Int = 0
    @State private var maxCreditAmount: Double = 0
    @State private var canTakeCredit: Bool = false
    
    @State private var monthlyPayment: Double = 0
    @State private var overpayment: Double = 0
    @State private var totalAmount: Double = 0
    @State private var baseRate: Double = 16.0
    @State private var showResult: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showSaveConfirmation: Bool = false
    @State private var userBalance: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Credit Score Info
            VStack(alignment: .leading, spacing: 8) {
                Text("Кредитный рейтинг: \(creditScore)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Максимальная сумма кредита: \(maxCreditAmount.formattedCurrency()) ₽")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                if !canTakeCredit {
                    Text("⚠️ В данный момент вы не можете взять кредит")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            
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
            
            if let error = errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
            
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
                
                Button(action: {
                    saveCredit()
                }) {
                    Text("Оформить кредит")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canTakeCredit ? Color.blue : Color.gray)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
                .disabled(!canTakeCredit)
                .padding(.top, 12)
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
        .alert(isPresented: $showSaveConfirmation) {
            Alert(
                title: Text("Кредит оформлен"),
                message: Text("Данные вашего кредита успешно сохранены."),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            updateUserBalance()
            updateCreditInfo()
        }
    }
    
    private func updateCreditInfo() {
        if let user = CoreDataManager.shared.fetchUser() {
            creditScore = CreditHistoryManager.shared.calculateCreditScore(for: user)
            maxCreditAmount = CreditHistoryManager.shared.getMaxCreditAmount(for: user)
            canTakeCredit = CreditHistoryManager.shared.canTakeCredit(for: user)
            baseRate = CreditHistoryManager.shared.getCreditInterestRate(for: user)
        }
    }
    
    private func saveCredit() {
        guard canTakeCredit else {
            errorMessage = "Вы не можете взять кредит в данный момент"
            return
        }
        
        let cleanAmount = Double(amount.replacingOccurrences(of: " ", with: "")) ?? 0
        let termMonths = Int(months) ?? 0
        
        guard let currentUser = CoreDataManager.shared.fetchUser() else {
            print("Пользователь не найден, кредит не сохранён")
            return
        }
        
        CoreDataManager.shared.saveLoan(
            amount: cleanAmount,
            termMonths: termMonths,
            rate: baseRate,
            monthlyPayment: monthlyPayment,
            totalAmount: totalAmount,
            user: currentUser
        )
        
        // Update user's balance
        currentUser.balance += cleanAmount
        CoreDataManager.shared.saveContext()
        
        showSaveConfirmation = true
        updateCreditInfo()
        updateUserBalance()
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
        
        if amountValue > maxCreditAmount {
            errorMessage = "Максимальная сумма кредита - \(maxCreditAmount.formattedCurrency()) ₽"
            return
        }
        
        if monthsValue < 1 {
            errorMessage = "Минимальный срок - 1 месяц"
            return
        }
        
        if monthsValue > 60 {
            errorMessage = "Максимальный срок кредита - 5 лет (60 месяцев)"
            return
        }
        
        if !canTakeCredit {
            errorMessage = "В данный момент вы не можете взять кредит"
            return
        }
    }
    
    private func calculatePayment() {
        let cleanAmount = amount.replacingOccurrences(of: " ", with: "")
        let amountValue = Double(cleanAmount) ?? 0
        let monthsValue = Double(months) ?? 0
        
        guard amountValue >= 10000, monthsValue >= 1, errorMessage == nil else {
            showResult = false
            return
        }
        
        let monthlyRate = baseRate / 100 / 12
        let payment = amountValue * monthlyRate * pow(1 + monthlyRate, monthsValue) / (pow(1 + monthlyRate, monthsValue) - 1)
        
        monthlyPayment = payment
        totalAmount = payment * monthsValue
        overpayment = totalAmount - amountValue
        showResult = true
    }
    
    private func updateUserBalance() {
        if let user = CoreDataManager.shared.fetchUser() {
            userBalance = user.balance
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

