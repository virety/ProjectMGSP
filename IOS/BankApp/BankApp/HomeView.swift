import SwiftUI
import LocalAuthentication

struct HomeView: View {
    @Binding var isAuthenticated: Bool
    @State private var timeGreeting: String = ""
    @State private var userName: String = "Иван"
    @State private var authType: AuthType = .pin
    @State private var showGreeting = true
    @State private var authError: String?
    @State private var pinCode: String = ""
    @State private var showPinKeyboard = false
    @State private var pinAttempts = 0
    
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
                    BankView()
                } else {
                    authContent
                }
            }
        }
        .onAppear(perform: updateGreeting)
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
            Button("Попробовать снова") {
                authError = nil
                startAuthentication()
            }
            Button("Отмена", role: .cancel) {
                authError = nil
                resetAuthState()
            }
        }, message: {
            Text(authError ?? "")
        })
    }
    
    private var greetingView: some View {
        VStack {
            Text(timeGreeting)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
            
            Text(userName)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 8)
            
            Spacer().frame(height: 100)
            
            Button(action: {
                withAnimation {
                    showGreeting = false
                }
            }) {
                Text("Выберите способ входа")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue.opacity(0.7))
                    .cornerRadius(10)
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
            
            Button(action: {
                withAnimation {
                    showGreeting = true
                }
            }) {
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
        case 6..<12: "Доброе утро"
        case 12..<18: "Добрый день"
        case 18..<23: "Добрый вечер"
        default: "Доброй ночи"
        }
    }
    
    private func startAuthentication() {
        switch authType {
        case .pin:
            withAnimation {
                showPinKeyboard = true
            }
        case .faceID, .touchID:
            authenticateWithBiometrics()
        }
    }
    
    private func hidePinKeyboard() {
        withAnimation {
            showPinKeyboard = false
            showGreeting = true
        }
    }
    
    private func resetAuthState() {
        withAnimation {
            showPinKeyboard = false
            showGreeting = true
        }
        pinCode = ""
        pinAttempts = 0
    }
    
    private func verifyPin(_ pin: String) {
        let correctPin = "1234" // Замените на реальную проверку
        
        if pin == correctPin {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    isAuthenticated = true
                }
            }
        } else {
            pinAttempts += 1
            if pinAttempts >= 3 {
                authError = "Неверный PIN. Попробуйте другой способ входа."
                resetAuthState()
            } else {
                authError = "Неверный PIN. Осталось попыток: \(3 - pinAttempts)"
                pinCode = ""
            }
        }
    }
    
    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Используйте \(authType.rawValue) для входа"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        withAnimation {
                            self.isAuthenticated = true
                        }
                    } else {
                        self.authError = error?.localizedDescription ?? "Ошибка аутентификации"
                    }
                }
            }
        } else {
            authError = "\(authType.rawValue) недоступен"
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


#Preview {
    HomeView(isAuthenticated: .constant(false))
        .preferredColorScheme(.dark)
}
