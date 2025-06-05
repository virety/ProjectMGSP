import SwiftUI
import LocalAuthentication
import Foundation
import CoreData

struct PersistenceController {
    func resetAuthState(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        do {
            let users = try context.fetch(fetchRequest)
            for user in users {
                user.isAuthenticated = false
            }
            try context.save()
        } catch {
            print("Error resetting auth state: \(error)")
        }
    }
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    

    
    // MARK: - Preview
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        return result
    }()
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Model")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}

struct HomeView: View {
    @Binding var isAuthenticated: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @State private var currentUser: CDUser?
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDUser.firstName, ascending: true)],
        animation: .default)
    private var users: FetchedResults<CDUser>
    @State private var timeGreeting: String = ""
    @State private var userName: String?
    @State private var authType: AuthType = .pin
    @State private var showGreeting = true
    @State private var authError: String?
    @State private var pinCode: String = ""
    @State private var showPinKeyboard = false
    @State private var pinAttempts = 0
    @State private var showRegistration = false
    @State private var userExists: Bool = false
    @State private var errorMessage: String?
    
    enum AuthType: String, CaseIterable {
        case faceID = "Face ID"
        case touchID = "Touch ID"
        case pin = "PIN-код"
        
        var icon: String {
            switch self {
            case .faceID: return "faceid"
            case .touchID: return "touchid"
            case .pin: return "key.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("space_background")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
                if isAuthenticated {
                    BankHomeView()
                } else if showRegistration {
                    RegistrationView(
                        onComplete: { userData in
                            UserDefaults.standard.set("\(userData.firstName) \(userData.lastName)", forKey: "userName")
                            isAuthenticated = true
                        },
                        onLoginInstead: {
                            showRegistration = false
                            checkUserExists()
                        }
                    )
                    .environment(\.managedObjectContext, viewContext)
                } else {
                    authContent
                }
            }
        }
        .onAppear {
            updateGreeting()
            checkUserExists()
        }
        .onChange(of: showGreeting) { newValue in
            if newValue {
                updateGreeting()
            }
        }
    }

    
    private var authContent: some View {
        Group {
            if showGreeting {
                greetingView
                    .transition(.opacity)
            } else {
                authOptionsView
                    .transition(.move(edge: .bottom))
            }
            
            if showPinKeyboard {
                PinKeyboardView(
                    pinCode: $pinCode,
                    onComplete: verifyPin,
                    onCancel: hidePinKeyboard
                )
                .zIndex(1)
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.default, value: showGreeting)
        .animation(.default, value: showPinKeyboard)
        .alert("Ошибка", isPresented: .constant(authError != nil), actions: {
            Button("Попробовать снова") { authError = nil }
            Button("Отмена", role: .cancel) { resetAuthState() }
        }, message: {
            Text(authError ?? "")
        })
    }
    
    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Используйте \(authType.rawValue) для входа"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        isAuthenticated = true
                    } else {
                        authError = error?.localizedDescription ?? "Ошибка аутентификации"
                    }
                }
            }
        } else {
            authError = "\(authType.rawValue) недоступен"
        }
    }

    
    private var greetingView: some View {
        VStack {
            Text(timeGreeting)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
            
            if let name = userName {
                Text(name)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.top, 8)
            }
            
            Spacer().frame(height: 100)
            
            if userExists {
                VStack(spacing: 20) {
                    Button(action: { showGreeting = false }) {
                        Text("Выберите способ входа")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue.opacity(0.7))
                        .cornerRadius(10)                    }
                    
                    Button(action: { showRegistration = true }) {
                        Text("Создать другой аккаунт?")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Button(action: { showRegistration = true }) {
                        Text("Зарегистрироваться")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.7))
                            .cornerRadius(10)
                    }
                    
                    Button(action: { showGreeting = false }) {
                        Text("У меня есть аккаунт")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 40)
            }
        }
        .padding(.top, 50)
    }
    
    private var authOptionsView: some View {
        VStack(spacing: 20) {
            ForEach(AuthType.allCases, id: \.self) { type in
                Button(action: {
                    authType = type
                    startAuthentication()
                }) {
                    HStack {
                        Image(systemName: type.icon)
                            .font(.title2)
                        Text(type.rawValue)
                            .font(.system(size: 18, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.7))
                    .cornerRadius(10)
                }
            }
            
            Button(action: { showGreeting = true }) {
                Text("Назад")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.top, 20)
        }
        .padding(.horizontal, 40)
    }
    
    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        timeGreeting = switch hour {
        case 6..<12: "Доброе утро,"
        case 12..<18: "Добрый день,"
        case 18..<23: "Добрый вечер,"
        default: "Доброй ночи,"
        }
    }


    
    private func checkUserExists() {
        let fetchRequest = NSFetchRequest<CDUser>(entityName: "CDUser")
        fetchRequest.fetchLimit = 1
        
        do {
            let users = try viewContext.fetch(fetchRequest)
            userExists = !users.isEmpty
            userName = users.first.map { user in
                return "\(user.lastName ?? "") \(user.firstName ?? "")"
            }
        } catch {
            print("Ошибка загрузки пользователей: \(error)")
        }
    }
    
    private func startAuthentication() {
        switch authType {
        case .pin: showPinKeyboard = true
        case .faceID, .touchID: authenticateWithBiometrics()
        }
    }
    
    private func hidePinKeyboard() {
        showPinKeyboard = false
        showGreeting = true
    }
    
    private func resetAuthState() {
        showPinKeyboard = false
        showGreeting = true
        pinCode = ""
        pinAttempts = 0
    }
    
    private func verifyPin(_ pin: String) {
        let fetchRequest = NSFetchRequest<CDUser>(entityName: "CDUser")
        fetchRequest.fetchLimit = 1
        
        do {
            let users = try viewContext.fetch(fetchRequest)
            guard let user = users.first else {
                authError = "Пользователь не найден"
                return
            }
            
            if pin == user.pin {
                currentUser = user
                isAuthenticated = true
                // Сохраняем имя пользователя
                UserDefaults.standard.set("\(user.firstName ?? "") \(user.lastName ?? "")", forKey: "userName")
            } else {
                pinAttempts += 1
                authError = pinAttempts >= 3 ?
                    "Неверный PIN. Попробуйте другой способ входа." :
                    "Неверный PIN. Осталось попыток: \(3 - pinAttempts)"
                if pinAttempts >= 3 {
                    resetAuthState()
                }
            }
        } catch {
            authError = "Ошибка проверки PIN"
        }
    }
}


struct UserData {
    let firstName: String
    let lastName: String
    let phoneNumber: String
    let cardNumber: String
    let pin: String
}

struct RegistrationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let onComplete: (UserData) -> Void
    let onLoginInstead: () -> Void
    @State private var middleName: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var phoneNumber: String = ""
    @State private var cardNumber: String = ""
    @State private var pin: String = ""
    @State private var confirmPin: String = ""
    @State private var currentStep: Int = 1
    @State private var errorMessage: String?
    
    private func completeRegistration() {
        guard pin.count == 4 else {
            errorMessage = "PIN должен содержать 4 цифры"
            return
        }
        
        guard pin == confirmPin else {
            errorMessage = "PIN-коды не совпадают"
            return
        }
        
        let cleanPhone = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let cleanCard = cardNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        let userData = UserData(
            firstName: firstName,
            lastName: lastName,
            phoneNumber: cleanPhone,
            cardNumber: cleanCard,
            pin: pin
        )
        
        // Сохраняем в CoreData
        let newUser = CDUser(context: viewContext)
        newUser.firstName = firstName
        newUser.lastName = lastName
        newUser.phoneNumber = cleanPhone
        newUser.cardNumber = cleanCard
        newUser.pin = pin
        
        do {
            try viewContext.save()
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "userName")
            onComplete(userData)
        } catch {
            errorMessage = "Ошибка сохранения: \(error.localizedDescription)"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Шапка с заголовком
            Text("")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 30)
                .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 20) {
                    if currentStep == 1 {
                        Group {
                            CustomTextField(
                                text: $lastName,
                                placeholder: "Введите фамилию",
                                icon: "person.fill",
                                color: .blue
                            )
                            CustomTextField(
                                text: $firstName,
                                placeholder: "Введите имя",
                                icon: "person.fill",
                                color: .blue
                            )
                            CustomTextField(
                                text: $middleName,
                                placeholder: "Введите отчество (необязательно)",
                                icon: "person.fill",
                                color: .blue
                            )
                            CustomTextField(
                                text: $phoneNumber,
                                placeholder: "Введите номер телефона",
                                icon: "phone.fill",
                                color: .green,
                                keyboardType: .phonePad,
                                formatter: formatPhoneNumber
                            )
                            CustomTextField(
                                text: $cardNumber,
                                placeholder: "Введите номер карты",
                                icon: "creditcard.fill",
                                color: .purple,
                                keyboardType: .numberPad,
                                formatter: formatCardNumber
                            )
                        }
                        .padding(.horizontal, 30)
                        GradientButton(
                            title: "Продолжить",
                            colors: [.blue, .purple],
                            action: validateStep1
                        )
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                        
                    } else {
                        // Шаг 2: PIN-код
                        Group {
                            CustomSecureField(
                                text: $pin,
                                placeholder: "Придумайте PIN-код (4 цифры)",
                                icon: "lock.fill",
                                color: .orange
                            )
                            
                            CustomSecureField(
                                text: $confirmPin,
                                placeholder: "Подтвердите PIN-код",
                                icon: "lock.fill",
                                color: .orange
                            )
                        }
                        .padding(.horizontal, 30)
                        
                        // Кнопка завершения
                        GradientButton(
                            title: "Завершить регистрацию",
                            colors: [.green, .blue],
                            action: completeRegistration
                        )
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .padding(.horizontal, 30)
                    }
                }
                .padding(.vertical, 20)
            }
            
            // Ссылка на вход
            Button(action: onLoginInstead) {
                Text("У меня уже есть аккаунт")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 30)
            }
        }
        .background(Color.black.opacity(0.5))
        .edgesIgnoringSafeArea(.all)
    }
    
    private func validateStep1() {
        guard !lastName.isEmpty else {
            errorMessage = "Введите фамилию"
            return
        }
        
        guard !firstName.isEmpty else {
            errorMessage = "Введите имя"
            return
        }
        
        let cleanPhone = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard cleanPhone.count == 11 else {
            errorMessage = "Введите корректный номер телефона"
            return
        }
        
        let cleanCard = cardNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard cleanCard.count == 16 else {
            errorMessage = "Введите корректный номер карты (16 цифр)"
            return
        }
        
        errorMessage = nil
        withAnimation {
            currentStep = 2
        }
    }
}

struct PinKeyboardView: View {
    @Binding var pinCode: String
    let onComplete: (String) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 20) {
                ForEach(0..<4) { index in
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .overlay(
                            pinCode.count > index ?
                            Circle().fill(Color.white) : nil
                        )
                }
            }
            .padding(.bottom, 30)
            
            NumberPadView(
                onNumberTap: { number in
                    if pinCode.count < 4 {
                        pinCode += number
                        if pinCode.count == 4 {
                            onComplete(pinCode)
                        }
                    }
                },
                onDelete: {
                    if !pinCode.isEmpty {
                        pinCode.removeLast()
                    }
                },
                onCancel: onCancel
            )
            
            Spacer().frame(height: 50)
        }
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.8))
        .edgesIgnoringSafeArea(.all)
    }
}

struct NumberPadView: View {
    let onNumberTap: (String) -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            ForEach([["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"]], id: \.self) { row in
                HStack(spacing: 30) {
                    ForEach(row, id: \.self) { number in
                        Button(action: { onNumberTap(number) }) {
                            Text(number)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 70, height: 70)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
            }
            
            HStack(spacing: 30) {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                }
                
                Button(action: { onNumberTap("0") }) {
                    Text("0")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button(action: onDelete) {
                    Image(systemName: "delete.left")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                }
            }
        }
    }
}

// Кастомное текстовое поле
struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    let color: Color
    var keyboardType: UIKeyboardType = .default
    var formatter: ((String) -> String)? = nil
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(Color(.black))
                        .padding(.leading, 4)
                        .shadow(color: Color(.black).opacity(0.3), radius: 4, x: 0, y: 0)
                        .shadow(color: Color(.blue).opacity(0.4), radius: 8, x: 0, y: 0)
                }
                
                TextField("", text: Binding(
                    get: { text },
                    set: { newValue in
                        text = formatter?(newValue) ?? newValue
                    }
                ))
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .foregroundColor(.primary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "5E60BB").opacity(0.8),
                            Color(hex: "B2F7FF").opacity(0.4)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 2)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


// Кастомное поле для пароля
struct CustomSecureField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            SecureField(placeholder, text: $text)
                .keyboardType(.numberPad)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

// Кнопка с градиентом
struct GradientButton: View {
    let title: String
    let colors: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: colors),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .cornerRadius(15)
                )
                .shadow(color: colors.first?.opacity(0.4) ?? .blue, radius: 10, x: 0, y: 5)
        }
    }
}

private func formatPhoneNumber(_ number: String) -> String {
    let digits = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    let trimmed = digits.hasPrefix("8") ? String(digits.dropFirst()) : digits
    let clean = trimmed.hasPrefix("7") ? String(trimmed.dropFirst()) : trimmed

    var result = "+7 "
    
    for (index, char) in clean.enumerated() {
        switch index {
        case 0: result += "(\(char)"
        case 2: result += "\(char)) "
        case 5, 7: result += "\(char)-"
        default: result += "\(char)"
        }
        if index >= 9 { break }
    }
    
    return result
}

private func formatCardNumber(_ number: String) -> String {
    let digits = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    let limited = String(digits.prefix(16))
    
    return stride(from: 0, to: limited.count, by: 4).map {
        let start = limited.index(limited.startIndex, offsetBy: $0)
        let end = limited.index(start, offsetBy: 4, limitedBy: limited.endIndex) ?? limited.endIndex
        return String(limited[start..<end])
    }.joined(separator: " ")
}


#Preview {
    let context = PersistenceController.preview.container.viewContext
    return HomeView(isAuthenticated: .constant(false))
        .environment(\.managedObjectContext, context)
        .preferredColorScheme(.dark)
}
