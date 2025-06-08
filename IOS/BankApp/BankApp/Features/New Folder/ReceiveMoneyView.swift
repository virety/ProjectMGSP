import SwiftUI
import MapKit
import CoreLocation
import CoreData

struct ReceiveMoneyView: View {
    enum ReceiveMethod: String, CaseIterable, Identifiable {
        case requisites = "Реквизиты"
        case cash = "Наличные"
        var id: String { rawValue }
    }

    @State private var selectedMethod: ReceiveMethod = .requisites
    @State private var recipientName: String = ""
    @State private var phoneNumber: String = ""
    @State private var cardNumber: String = ""
    @State private var amount: String = ""
    @State private var selectedTerminalID: UUID? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var locationManager = LocationManager()

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.1155, longitude: 131.8855),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    @State private var terminals: [Terminal] = [
        Terminal(name: "Терминал №8", address: "ул. Центральная, 10, Артем", distance: "12.5 км", isATM: false, coordinates: CLLocationCoordinate2D(latitude: 43.3890, longitude: 132.1900)),
        Terminal(name: "Терминал №3", address: "ул. Пушкинская, 20, Владивосток", distance: "0.5 км", isATM: true, coordinates: CLLocationCoordinate2D(latitude: 43.1189, longitude: 131.8812)),
        Terminal(name: "Терминал №1", address: "ул. Светланская, 1, Владивосток", distance: "0.2 км", isATM: true, coordinates: CLLocationCoordinate2D(latitude: 43.1168, longitude: 131.8875)),
        Terminal(name: "Терминал №11", address: "ул. Гагарина, 12, Артем", distance: "14.5 км", isATM: true, coordinates: CLLocationCoordinate2D(latitude: 43.3920, longitude: 132.1960)),
        Terminal(name: "Терминал №5", address: "ул. Тигровая, 10, Владивосток", distance: "0.8 км", isATM: true, coordinates: CLLocationCoordinate2D(latitude: 43.1125, longitude: 131.8860)),
        Terminal(name: "Терминал №10", address: "ул. Советская, 7, Артем", distance: "14.0 км", isATM: false, coordinates: CLLocationCoordinate2D(latitude: 43.3915, longitude: 132.1950)),
        Terminal(name: "Терминал №4", address: "ул. Адмирала Фокина, 8, Владивосток", distance: "0.6 км", isATM: false, coordinates: CLLocationCoordinate2D(latitude: 43.1150, longitude: 131.8850)),
        Terminal(name: "Терминал №7", address: "ул. Лазо, 3, Артем", distance: "12.0 км", isATM: true, coordinates: CLLocationCoordinate2D(latitude: 43.3870, longitude: 132.1870)),
        Terminal(name: "Терминал №9", address: "ул. Пушкина, 5, Артем", distance: "13.0 км", isATM: true, coordinates: CLLocationCoordinate2D(latitude: 43.3905, longitude: 132.1935)),
        Terminal(name: "Терминал №2", address: "ул. Алеутская, 15, Владивосток", distance: "0.4 км", isATM: false, coordinates: CLLocationCoordinate2D(latitude: 43.1175, longitude: 131.8831)),
        Terminal(name: "Терминал №6", address: "пр. Красного Знамени, 25, Владивосток", distance: "1.0 км", isATM: false, coordinates: CLLocationCoordinate2D(latitude: 43.1210, longitude: 131.8899)),
    ]

    private var allAnnotations: [Terminal] {
        var combined = terminals
        if let userLocation = locationManager.lastLocation {
            combined.append(
                Terminal(
                    name: "Вы здесь",
                    address: "",
                    distance: "",
                    isATM: false,
                    coordinates: userLocation
                )
            )
        }
        return combined
    }

    private let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.06, green: 0.04, blue: 0.15),
            Color(red: 0.15, green: 0.08, blue: 0.35),
            Color(red: 0.25, green: 0.13, blue: 0.45)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // === Верхний таб бар (оставляем без изменений)
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

                        Image(systemName: "tray.and.arrow.down.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        Text("Получить деньги")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        Spacer()
                    }
                    .frame(height: 64, alignment: .center)
                    .padding(.horizontal)
                }

                // === Picker способа получения
                Picker("Способ получения", selection: $selectedMethod) {
                    ForEach(ReceiveMethod.allCases) { method in
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

                // === Основной контент в зависимости от выбранного способа
                if selectedMethod == .requisites {
                    VStack(spacing: 16) {
                        Group {
                            CustomInputField(iconName: "person.fill", placeholder: "Имя получателя", text: $recipientName, keyboard: .default)

                            CustomPhoneInputField(phoneNumber: $phoneNumber)

                            CustomInputField(iconName: "creditcard.fill", placeholder: "Номер карты", text: $cardNumber, keyboard: .numberPad)

                            CustomInputField(iconName: "rublesign.circle.fill", placeholder: "Сумма", text: $amount, keyboard: .decimalPad)
                        }

                        Button(action: submitReceiveRequest) {
                            Text("Получить")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .font(.headline)
                                .cornerRadius(12)
                                .shadow(color: Color.purple.opacity(0.6), radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 16) {
                        Map(coordinateRegion: $region, annotationItems: allAnnotations) { terminal in
                            MapAnnotation(coordinate: terminal.coordinates) {
                                TerminalMapPin(isATM: terminal.isATM)
                            }
                        }
                        .frame(height: 250)
                        .cornerRadius(12)
                        .padding(.horizontal)

                        // Вертикальный список терминалов
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(terminals) { terminal in
                                    TerminalCardView(terminal: terminal, isSelected: selectedTerminalID == terminal.id)
                                        .onTapGesture {
                                            withAnimation {
                                                selectedTerminalID = terminal.id
                                                region.center = terminal.coordinates
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 280) // Ограничим высоту списка под картой
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .alert("Успешно", isPresented: $showSuccessAlert) {
            Button("OK") {
                resetForm()
                dismiss()
            }
        } message: {
            Text("Деньги успешно получены")
        }
        .alert("Ошибка", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            if let userCoord = locationManager.lastLocation {
                region.center = userCoord
            }
        }
    }

    // MARK: - Вспомогательные функции

    private func submitReceiveRequest() {
        guard !recipientName.isEmpty else {
            showError(message: "Введите имя получателя")
            return
        }

        guard !phoneNumber.isEmpty else {
            showError(message: "Введите номер телефона")
            return
        }

        guard !cardNumber.isEmpty else {
            showError(message: "Введите номер карты")
            return
        }

        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")), amountValue > 0 else {
            showError(message: "Введите корректную сумму")
            return
        }

        let newTransaction = CDTransaction(context: viewContext)
        newTransaction.id = UUID()
        newTransaction.type = 0 // Доход
        newTransaction.title = "Поступление от \(recipientName)"
        newTransaction.date = Date()
        newTransaction.amount = amountValue

        let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isAuthenticated == true")
        do {
            let users = try viewContext.fetch(fetchRequest)
            if let currentUser = users.first {
                currentUser.balance += amountValue
                newTransaction.user = currentUser
            } else {
                showError(message: "Ошибка авторизации")
                return
            }
            try viewContext.save()
            showSuccessAlert = true
        } catch {
            showError(message: "Не удалось сохранить транзакцию или обновить баланс: \(error.localizedDescription)")
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showErrorAlert = true
    }

    private func resetForm() {
        recipientName = ""
        phoneNumber = ""
        cardNumber = ""
        amount = ""
        selectedTerminalID = nil
    }

    private func formatPhoneNumber(_ digits: String) -> String {
        var result = "+7 "
        let numbers = digits.dropFirst(digits.first == "7" ? 1 : 0)

        for (index, digit) in numbers.enumerated() {
            switch index {
            case 0: result += "(\(digit)"
            case 2: result += "\(digit)) "
            case 5: result += "\(digit)-"
            case 7: result += "\(digit)-"
            default: result += "\(digit)"
            }
        }
        return result
    }
}

// MARK: - Кастомные поля ввода для красивого UI

struct CustomInputField: View {
    let iconName: String
    let placeholder: String
    @Binding var text: String
    let keyboard: UIKeyboardType

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.purple.opacity(0.7))
                .cornerRadius(8)
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .foregroundColor(.white)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.15))
                        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                )
        }
    }
}

struct CustomPhoneInputField: View {
    @Binding var phoneNumber: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                Image(systemName: "phone.fill")
                    .foregroundColor(.white)
            }

            TextField("Телефон", text: $phoneNumber)
                .keyboardType(.numberPad)
                .foregroundColor(.white)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.15))
                        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                )
                .onChange(of: phoneNumber) { newValue in
                    // Убираем все символы кроме цифр и ограничиваем длину
                    let digits = newValue.filter { $0.isNumber }
                    if digits.count <= 11 {
                        phoneNumber = formatPhoneNumber(digits)
                    } else {
                        phoneNumber = formatPhoneNumber(String(digits.prefix(11)))
                    }
                }
        }
    }

    private func formatPhoneNumber(_ digits: String) -> String {
        var result = "+7 "
        let numbers = digits.dropFirst(digits.first == "7" ? 1 : 0)

        for (index, digit) in numbers.enumerated() {
            switch index {
            case 0: result += "(\(digit)"
            case 2: result += "\(digit)) "
            case 5: result += "\(digit)-"
            case 7: result += "\(digit)-"
            default: result += "\(digit)"
            }
        }
        return result
    }
}

// MARK: - Вид карты с пином терминала

struct TerminalMapPin: View {
    var isATM: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isATM ? Color.orange : Color.purple)
                .frame(width: 28, height: 28)
                .shadow(radius: 5)
            Image(systemName: isATM ? "banknote.fill" : "creditcard.fill")
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .bold))
        }
    }
}

// MARK: - Карточка терминала в списке

struct TerminalCardView: View {
    let terminal: Terminal
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            TerminalMapPin(isATM: terminal.isATM)
            VStack(alignment: .leading, spacing: 4) {
                Text(terminal.name)
                    .font(.headline)
                    .foregroundColor(isSelected ? .purple : .white)
                Text(terminal.address)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                if !terminal.distance.isEmpty {
                    Text(terminal.distance)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.purple)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
        )
    }
}
