import SwiftUI
import CoreData

struct CreditCalculatorView: View {
    @State private var amount: String = ""
    @State private var months: String = ""
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
                            creditToUserBalance() // Пополнение баланса
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
                    withdrawFromUserBalance() // Списание при оформлении
                }) {
                    Text("Оформить кредит")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
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
                title: Text("Кредит оформлен"),
                message: Text("Данные вашего кредита успешно сохранены."),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            updateUserBalance()
        }
    }
    
    private func creditToUserBalance() {
        let cleanAmount = Double(amount.replacingOccurrences(of: " ", with: "")) ?? 0
        guard cleanAmount >= 10000 else { return }
        
        if let user = CoreDataManager.shared.fetchUser() {
            user.balance += cleanAmount
            CoreDataManager.shared.saveContext()
            updateUserBalance()
        }
    }
    
    private func withdrawFromUserBalance() {
        if let user = CoreDataManager.shared.fetchUser() {
            if user.balance >= totalAmount {
                user.balance -= totalAmount
                CoreDataManager.shared.saveContext()
                updateUserBalance()
            } else {
                errorMessage = "Недостаточно средств на счете"
            }
        }
    }
    
    private func updateUserBalance() {
        if let user = CoreDataManager.shared.fetchUser() {
            userBalance = user.balance
        }
    }
    
    private func saveCredit() {
        let cleanAmount = Double(amount.replacingOccurrences(of: " ", with: "")) ?? 0
        let termMonths = Int(months) ?? 0
        
        CoreDataManager.shared.saveLoan(
            amount: cleanAmount,
            termMonths: termMonths,
            rate: baseRate,
            monthlyPayment: monthlyPayment,
            totalAmount: totalAmount
        )
        
        showSaveConfirmation = true
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
        
        if amountValue <= 30000 && monthsValue <= 12 {
            baseRate = 6.0
        } else if amountValue <= 300000 && monthsValue <= 36 {
            baseRate = 12.0
        } else {
            baseRate = 16.0
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

