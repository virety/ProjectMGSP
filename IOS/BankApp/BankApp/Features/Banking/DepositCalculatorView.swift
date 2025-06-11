import SwiftUI

// MARK: - Калькулятор вклада
struct DepositCalculatorView: View {
    @State private var amount: String = ""
    @State private var months: String = ""
    @State private var totalAmount: Double = 0
    @State private var income: Double = 0
    @State private var baseRate: Double = 16.0
    @State private var showResult: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showSaveConfirmation: Bool = false
    @State private var userBalance: Double = 0

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
                
                Button(action: {
                    saveDeposit()
                    withdrawFromBalance()
                }) {
                    Text("Сохранить вклад")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
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
                title: Text("Вклад сохранён"),
                message: Text("Данные вашего вклада успешно сохранены."),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            updateUserBalance()
        }
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
        
        if amountValue > userBalance {
            errorMessage = "Недостаточно средств на балансе"
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
            baseRate = 10.0
        } else {
            baseRate = 16.0
        }
        
        let r = baseRate / 100 / 12
        let n = rawMonths
        totalAmount = rawAmount * pow(1 + r, n)
        income = totalAmount - rawAmount
        showResult = true
    }

    private func saveDeposit() {
        let cleanAmount = Double(amount.replacingOccurrences(of: " ", with: "")) ?? 0
        let term = Int(months) ?? 0

        guard let currentUser = CoreDataManager.shared.fetchUser() else {
            print("Пользователь не найден, депозит не сохранён")
            return
        }

        CoreDataManager.shared.saveDeposit(
            amount: cleanAmount,
            termMonths: term,
            interestRate: baseRate,
            totalInterest: income,
            user: currentUser
        )

        showSaveConfirmation = true
    }


    private func withdrawFromBalance() {
        let cleanAmount = Double(amount.replacingOccurrences(of: " ", with: "")) ?? 0
        
        if let user = CoreDataManager.shared.fetchUser() {
            if user.balance >= cleanAmount {
                user.balance -= cleanAmount
                CoreDataManager.shared.saveContext()
                updateUserBalance()
            } else {
                errorMessage = "Недостаточно средств на балансе"
            }
        }
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
