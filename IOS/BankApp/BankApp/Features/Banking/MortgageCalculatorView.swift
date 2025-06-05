//
//  MortgageCalculatorView.swift
//  BankApp
//
//  Created by Вадим Семибратов on 05.06.2025.
//

import SwiftUI

// MARK: - Калькулятор ипотеки
struct MortgageCalculatorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var cost: String = ""
    @State private var firstPayment: String = ""
    @State private var years: String = ""
    
    @State private var monthlyPayment: Double = 0
    @State private var totalAmount: Double = 0
    @State private var overpayment: Double = 0
    @State private var loanAmount: Double = 0
    @State private var showResult: Bool = false
    @State private var errorMessage: String? = nil
    @State private var centralBankRate: Double = 16.0
    @State private var isLoadingRate: Bool = false
    @State private var showSuccessAlert: Bool = false
    
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
                    
                    Button(action: applyForMortgage) {
                        Text("Оформить ипотеку")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .padding(.top, 8)
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
        .alert("Ипотека оформлена", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Информация сохранена в вашем профиле")
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
        loanAmount = S // Store loan amount for later use
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
    
    private func applyForMortgage() {
        let yearsValue = Double(years) ?? 0
        
        let mortgage = Mortgage(context: viewContext)
        mortgage.amount = loanAmount
        mortgage.termYears = Int16(yearsValue)
        mortgage.rate = centralBankRate
        mortgage.monthlyPayment = monthlyPayment
        mortgage.totalPayment = totalAmount
        mortgage.overpayment = overpayment
        mortgage.date = Date()
        
        do {
            try viewContext.save()
            print("Ипотека успешно сохранена в CoreData")
            showSuccessAlert = true
        } catch {
            print("Ошибка сохранения ипотеки: \(error)")
            errorMessage = "Ошибка при сохранении данных"
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

