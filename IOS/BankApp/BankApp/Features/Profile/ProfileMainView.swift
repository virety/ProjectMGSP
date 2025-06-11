import SwiftUI
import PhotosUI
import CoreData

struct ProfileMainView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Mortgage.date, ascending: false)],
        animation: .default)
    private var mortgages: FetchedResults<Mortgage>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Loan.date, ascending: false)],
        animation: .default)
    private var loans: FetchedResults<Loan>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Deposit.date, ascending: false)],
        animation: .default)
    private var deposits: FetchedResults<Deposit>

    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isAuthenticated == true"),
        animation: .default)
    private var users: FetchedResults<CDUser>
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedTab: MainTabView.Tab
    
    @State private var showLogin = false
    @State private var showLogoutConfirm = false
    @State private var showPinPad = false
    @State private var enteredPin = ""
    @State private var currentUser: CDUser?
    @State private var selectedItem: PhotosPickerItem? = nil

    // Add computed properties to filter by authenticated user
    private var userMortgages: [Mortgage] {
        guard let currentUser = users.first else { return [] }
        return mortgages.filter { $0.user == currentUser }
    }
    
    private var userLoans: [Loan] {
        guard let currentUser = users.first else { return [] }
        return loans.filter { $0.user == currentUser }
    }
    
    private var userDeposits: [Deposit] {
        guard let currentUser = users.first else { return [] }
        return deposits.filter { $0.user == currentUser }
    }

    // Update computed properties to use filtered arrays
    private var mortgagesCount: Int {
        userMortgages.count
    }
    
    private var mortgagesTotalAmount: Double {
        userMortgages.reduce(0) { $0 + ($1.amount) }
    }

    private var loansCount: Int {
        userLoans.count
    }
    
    private var totalRemainingDebt: Double {
        userLoans.reduce(0) { $0 + ($1.remainingDebt) }
    }
    
    // Находим кредит с ближайшей будущей датой платежа
    private var nextLoanPayment: (date: Date?, amount: Double) {
        let now = Date()
        let futureLoans = userLoans.filter { loan in
            if let date = loan.nextPaymentDate {
                return date >= now
            }
            return false
        }
        let nearestLoan = futureLoans.min { ($0.nextPaymentDate ?? Date.distantFuture) < ($1.nextPaymentDate ?? Date.distantFuture) }
        
        if let loan = nearestLoan {
            return (loan.nextPaymentDate, loan.nextPaymentAmount)
        } else {
            return (nil, 0)
        }
    }
    
    private var depositsCount: Int {
        userDeposits.count
    }
    
    private var totalDepositsAmount: Double {
        userDeposits.reduce(0) { $0 + ($1.amount) }
    }
    
    private var averageDepositRate: Double {
        guard !userDeposits.isEmpty else { return 0 }
        let totalRate = userDeposits.reduce(0) { $0 + ($1.interestRate) }
        return totalRate / Double(userDeposits.count)
    }

    var body: some View {
        ZStack {
            // Градиентный фон
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.06, green: 0.04, blue: 0.15),
                    Color(red: 0.15, green: 0.08, blue: 0.35),
                    Color(red: 0.25, green: 0.13, blue: 0.45)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Верхний toolbar
                headerView()
                
                // Основное содержимое
                ScrollView {
                    VStack(spacing: 20) {
                        // Фото профиля
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            if let imageData = currentUser?.profileImageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.top, 20)
                        
                        // ФИО
                        if let user = currentUser {
                            Text("\(user.lastName ?? "") \(user.firstName ?? "") \(user.middleName ?? "")")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Единая таблица продуктов
                        productsTableView
                        
                        // Кнопка выхода
                        logoutButton
                    }
                }
                .blur(radius: showPinPad ? 3 : 0)
                
                if showPinPad {
                    pinEntryView
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            currentUser = users.first
        }
        .onChange(of: selectedItem) { _ in loadImage() }
        .fullScreenCover(isPresented: $showLogin) {
            HomeView(isAuthenticated: .constant(false))
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private var productsTableView: some View {
        VStack(spacing: 0) {
            // Секция вкладов
            HStack {
                Text("Вклады")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(depositsCount)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text("+\(formatCurrency(totalDepositsAmount)) ₽")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                    Text(String(format: "%.2f%%", averageDepositRate))
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            
            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.horizontal, 16)
            
            // Секция кредитов и платежей
            VStack(spacing: 12) {
                HStack {
                    Text("Кредиты")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(loansCount)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Остаток долга")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(formatCurrency(totalRemainingDebt)) ₽")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Ближайший платёж")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Spacer()
                    VStack(alignment: .trailing) {
                        if let nextDate = nextLoanPayment.date {
                            Text(formatDate(nextDate))
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                        Text("-\(formatCurrency(nextLoanPayment.amount)) ₽")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.horizontal, 16)
            
            // Секция ипотеки
            HStack {
                Text("Ипотека")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(mortgagesCount)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    if mortgagesCount > 0 {
                        Text("\(formatCurrency(mortgagesTotalAmount)) ₽")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 16)

        }
        .background(
            Color.white.opacity(0.1)
                .cornerRadius(12)
        )
        .padding(.horizontal)
    }
    
    private var logoutButton: some View {
        Button(action: { showLogoutConfirm = true }) {
            Text("Выйти")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.top, 20)
        .padding(.bottom, 30)
        .confirmationDialog("Вы уверены, что хотите выйти?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("Выйти", role: .destructive) { showPinPad = true }
            Button("Отмена", role: .cancel) {}
        }
    }
    
    private var pinEntryView: some View {
        VStack(spacing: 20) {
            Text("Введите PIN для выхода")
                .foregroundColor(.white)
                .font(.headline)
            
            SecureField("PIN", text: $enteredPin)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .frame(width: 200)
            
            HStack {
                Button("Отмена") {
                    enteredPin = ""
                    showPinPad = false
                }
                .foregroundColor(.white)
                .padding()
                
                Spacer()
                
                Button("Подтвердить") {
                    verifyPin()
                }
                .foregroundColor(.white)
                .padding()
            }
            .frame(width: 200)
        }
        .padding()
        .background(Color.gray.opacity(0.9))
        .cornerRadius(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.7))
        .edgesIgnoringSafeArea(.all)
    }
    
    private func headerView() -> some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .ignoresSafeArea(edges: .top)
                .frame(height: 56)
            
            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .font(.system(size: 18))
                Text("Профиль")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            
            HStack {
                Button(action: {
                    if presentationMode.wrappedValue.isPresented {
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        selectedTab = .home
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
                Spacer()
            }
            .padding(.horizontal)
        }
        .frame(height: 56)
    }
    
    private func loadImage() {
        Task {
            do {
                guard let item = selectedItem,
                      let data = try await item.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else {
                    throw ImageError.loadFailed
                }
                
                let compressedData = uiImage.jpegData(compressionQuality: 0.7)
                
                await MainActor.run {
                    currentUser?.profileImageData = compressedData
                    saveContext()
                }
            } catch {
                print("Failed to load image: \(error)")
            }
        }
    }
    
    private func verifyPin() {
        guard let user = currentUser else { return }

        if enteredPin == user.pin {
            enteredPin = ""
            showPinPad = false

            // Сброс состояния в Core Data
            user.isAuthenticated = false

            do {
                try viewContext.save()
                UserDefaults.standard.removeObject(forKey: "userName")
                showLogin = true
            } catch {
                print("Ошибка при сохранении isAuthenticated: \(error)")
            }
        } else {
            enteredPin = ""
            // Можно добавить вибрацию или уведомление
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter.string(from: date)
    }
    
    enum ImageError: Error {
        case loadFailed
    }
}

