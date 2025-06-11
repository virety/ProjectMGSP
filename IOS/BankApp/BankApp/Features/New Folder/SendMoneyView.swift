import SwiftUI
import CoreData

struct SendMoneyView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    enum TransferMethod: String, CaseIterable, Identifiable {
        case recipientName = "Получатель"
        case phoneNumber = "Телефон"
        case cardNumber = "Номер карты"
        var id: String { rawValue }
    }

    @FetchRequest(
        entity: CDUser.entity(),
        sortDescriptors: [],
        predicate: NSPredicate(format: "isAuthenticated == true")
    ) private var authenticatedUsers: FetchedResults<CDUser>

    @FetchRequest(
        entity: CDUser.entity(),
        sortDescriptors: []
    ) private var cards: FetchedResults<CDUser>

    @State private var selectedMethod: TransferMethod = .recipientName
    @State private var recipientName: String = ""
    @State private var phoneNumber: String = ""
    @State private var cardNumber: String = ""

    @State private var amountString: String = ""
    @State private var comment: String = ""

    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""

    private let buttonGradient = LinearGradient(
        gradient: Gradient(colors: [Color.purple, Color.blue]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    private let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.10, green: 0.06, blue: 0.20),
            Color(red: 0.17, green: 0.09, blue: 0.40),
            Color(red: 0.30, green: 0.17, blue: 0.55)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                customHeader()

                Picker("Способ перевода", selection: $selectedMethod) {
                    ForEach(TransferMethod.allCases) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.15))
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal)

                Group {
                    switch selectedMethod {
                    case .recipientName:
                        styledInputField(
                            iconName: "person.fill",
                            placeholder: "Имя получателя",
                            text: $recipientName,
                            keyboardType: .default,
                            textContentType: .name
                        )
                    case .phoneNumber:
                        styledInputField(
                            iconName: "phone.fill",
                            placeholder: "+7 123 456 78 90",
                            text: $phoneNumber,
                            keyboardType: .phonePad
                        )
                        .onChange(of: phoneNumber) { newValue in
                            phoneNumber = formatPhoneNumber(newValue)
                        }
                    case .cardNumber:
                        styledInputField(
                            iconName: "creditcard.fill",
                            placeholder: "1234 5678 9012 3456",
                            text: $cardNumber,
                            keyboardType: .numberPad
                        )
                        .onChange(of: cardNumber) { newValue in
                            cardNumber = formatCardNumber(newValue)
                        }
                    }
                }
                .padding(.horizontal)

                styledInputField(
                    iconName: "rublesign.circle.fill",
                    placeholder: "Сумма (руб.)",
                    text: $amountString,
                    keyboardType: .decimalPad
                )
                .padding(.horizontal)
                .onChange(of: amountString) { newValue in
                    amountString = formatAmount(newValue)
                }

                styledInputField(
                    iconName: "text.bubble.fill",
                    placeholder: "Комментарий (необязательно)",
                    text: $comment,
                    keyboardType: .default
                )
                .padding(.horizontal)

                Button(action: sendMoney) {
                    Text("Отправить")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(buttonGradient)
                        .cornerRadius(16)
                        .shadow(color: Color.purple.opacity(0.7), radius: 12, x: 0, y: 6)
                        .padding(.horizontal)
                        .scaleEffect(showErrorAlert || showSuccessAlert ? 0.95 : 1)
                        .animation(.spring(), value: showErrorAlert || showSuccessAlert)
                }
                .padding(.bottom, 30)

                Spacer()
            }
            .padding(.top)
        }
        .navigationBarHidden(true)
        .alert("Успех", isPresented: $showSuccessAlert) {
            Button("OK") {
                resetForm()
                dismiss()
            }
        } message: {
            Text("Перевод выполнен успешно")
        }
        .alert("Ошибка", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func customHeader() -> some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 56)
                .ignoresSafeArea(edges: .top)
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }

                Image(systemName: "paperplane.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.horizontal)

                Text("Отправить деньги")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal)

                Spacer()
            }
            .frame(height: 64, alignment: .center)
            .padding(.horizontal)
        }
    }

    private func resetForm() {
        recipientName = ""
        phoneNumber = ""
        cardNumber = ""
        amountString = ""
        comment = ""
    }

    private func styledInputField(
        iconName: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.purple.opacity(0.5), radius: 6, x: 0, y: 4)

                Image(systemName: iconName)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .semibold))
            }

            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .padding(14)
                .background(Color.white.opacity(0.12))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .foregroundColor(.white)
                .disableAutocorrection(true)
                .autocapitalization(.none)
        }
        .padding(.vertical, 6)
        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 4)
    }

    private func createTransaction(amount: Double, type: TransactionType) {
        guard let currentUser = authenticatedUsers.first else { return }
        
        let transaction = CDTransaction(context: viewContext)
        transaction.id = UUID()
        transaction.user = currentUser
        transaction.amount = amount
        transaction.date = Date()
        transaction.title = generateTransactionTitle()
        transaction.type = Int16(type == .income ? 0 : 1)
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving transaction: \(error)")
        }
    }

    private func generateTransactionTitle() -> String {
        switch selectedMethod {
        case .recipientName:
            return "Перевод \(recipientName)"
        case .phoneNumber:
            return "Перевод на \(phoneNumber)"
        case .cardNumber:
            return "Перевод на карту \(cardNumber)"
        }
    }

    private func sendMoney() {
        let cleanPhone = phoneNumber.replacingOccurrences(of: " ", with: "")
        let cleanCard = cardNumber.replacingOccurrences(of: " ", with: "")
        let cleanAmount = amountString.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: ",", with: ".")

        guard let currentUser = authenticatedUsers.first else {
            showError(message: "Ошибка авторизации")
            return
        }

        switch selectedMethod {
        case .recipientName:
            guard !recipientName.trimmingCharacters(in: .whitespaces).isEmpty else {
                showError(message: "Введите имя получателя")
                return
            }
        case .phoneNumber:
            guard isValidPhone(cleanPhone) else {
                showError(message: "Введите корректный номер телефона")
                return
            }
        case .cardNumber:
            guard isValidCard(cleanCard) else {
                showError(message: "Введите корректный номер карты")
                return
            }
        }

        guard let amount = Double(cleanAmount),
              amount > 0,
              amount <= currentUser.balance else {
            showError(message: "Недостаточно средств или некорректная сумма")
            return
        }

        // Update sender's balance
        currentUser.balance -= amount
        
        // Create transaction record
        createTransaction(amount: -amount, type: .expense)

        do {
            try viewContext.save()
            showSuccessAlert = true
        } catch {
            showError(message: "Ошибка при выполнении перевода")
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showErrorAlert = true
    }

    private func isValidPhone(_ phone: String) -> Bool {
        let phoneRegex = #"^\+?\d{7,15}$"#
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: phone)
    }

    private func isValidCard(_ card: String) -> Bool {
        return card.count == 16 && card.allSatisfy { $0.isNumber }
    }

    private func formatPhoneNumber(_ number: String) -> String {
        let filtered = number.filter { "+0123456789".contains($0) }
        var result = ""

        var digits = filtered
        if digits.hasPrefix("+") {
            result.append("+")
            digits.removeFirst()
        }

        for (index, digit) in digits.enumerated() {
            if index == 0 && !result.hasPrefix("+") {
                result.append("+")
            }
            if index == 1 || index == 4 || index == 7 || index == 9 {
                result.append(" ")
            }
            result.append(digit)
            if result.count > 17 { break }
        }
        return result
    }

    private func formatCardNumber(_ number: String) -> String {
        let filtered = number.filter { $0.isNumber }
        var result = ""
        for (index, digit) in filtered.enumerated() {
            if index != 0 && index % 4 == 0 {
                result.append(" ")
            }
            result.append(digit)
            if index >= 15 { break }
        }
        return result
    }

    private func formatAmount(_ amount: String) -> String {
        let filtered = amount.filter { "0123456789,.".contains($0) }
        let standardized = filtered.replacingOccurrences(of: ",", with: ".")

        if let value = Double(standardized) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = " "
            formatter.maximumFractionDigits = 2
            formatter.decimalSeparator = ","
            return formatter.string(from: NSNumber(value: value)) ?? amount
        }
        return amount
    }
}
