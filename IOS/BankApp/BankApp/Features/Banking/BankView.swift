import SwiftUI
import CoreData

struct BankCard: Identifiable {
    let id = UUID()
    let balance: String
    let info: String
    let number: String
    let expiry: String
    let gradientStart: Color
    let gradientEnd: Color
    let image: UIImage?
}

// MARK: - Главный TabView
struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @Environment(\.managedObjectContext) private var viewContext
    
    @ViewBuilder
    var selectedView: some View {
        switch selectedTab {
        case .home:
            BankHomeView()
        case .terminals:
            TerminalsView(selectedTab: $selectedTab)
        case .cards:
            CardsMainView(selectedTab: $selectedTab)
        case .profile:
            ProfileMainView(selectedTab: $selectedTab)
        }
    }
    
    enum Tab {
        case home
        case terminals
        case cards
        case profile
    }
    
    var body: some View {
        ZStack {
            // Градиентный фон на весь экран
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "F9F6FF"),
                    Color(hex: "B2F7FF"),
                    Color(hex: "5E60BB")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Контент текущей вкладки
            selectedView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Кастомный TabBar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .onAppear {
            setupDefaultBalances()
        }
    }
    
    private func setupDefaultBalances() {
        let request: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        
        do {
            let users = try viewContext.fetch(request)
            for user in users {
                if user.balance == 0 { // Проверяем, не установлен ли уже баланс
                    user.balance = 10000
                    print("Установлен баланс 10000 для пользователя \(user.firstName ?? "")")
                }
            }
            try viewContext.save()
        } catch {
            print("Ошибка при установке балансов: \(error)")
        }
    }
}

// MARK: - Bank Home View
struct BankHomeView: View {
    @FetchRequest(
        entity: CDTransaction.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CDTransaction.date, ascending: false)]
    ) private var cdTransactions: FetchedResults<CDTransaction>

    @FetchRequest(
        entity: CDUser.entity(),
        sortDescriptors: []
    ) private var users: FetchedResults<CDUser>
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showSendMoney = false
    @State private var showReceiveMoney = false
    @State private var showAIView = false
    @State private var isMoreActionsPresented = false
    @State private var isActionButtonView = false
    @State private var showCreateCard = false
    
    private func currentUserName() -> String {
        if let user = users.first {
            return user.firstName ?? "Пользователь"
        }
        return "Пользователь"
    }
    
    private func formatExpiryDate(_ date: Date?) -> String {
        guard let date = date else { return "MM/YY" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        return formatter.string(from: date)
    }
    
    private func createBankCard(for user: CDUser) -> BankCard {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        let balanceString = formatter.string(from: NSNumber(value: user.balance)) ?? "10 000"
        
        return BankCard(
            balance: "₽\(balanceString)",
            info: "\(user.firstName ?? "") \(user.lastName ?? "")",
            number: user.cardNumber ?? "**** **** **** ****",
            expiry: formatExpiryDate(user.cardExpiry),
            gradientStart: Color(red: 0.24, green: 0.18, blue: 0.91),
            gradientEnd: Color(red: 0.70, green: 0.28, blue: 1.00),
            image: user.cardImageData.flatMap { UIImage(data: $0) }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.06, green: 0.04, blue: 0.15),
                        Color(red: 0.25, green: 0.13, blue: 0.45)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Панель приветствия
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Привет, \(currentUserName())!")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                Text("Ваш баланс: ₽\(String(format: "%.2f", users.first?.balance ?? 10000))")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))

                            }
                            Spacer()
                            Button(action: { showAIView = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 18))
                                    Text("Ассистент")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.green)
                                .padding(8)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                            }
                            .fullScreenCover(isPresented: $showAIView ) {
                                AIView()
                            }
                            
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        // Карты пользователей
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                // Кнопка "+" ДО всех карт
                                Button(action: {
                                    showCreateCard = true
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(
                                                colors: [Color.purple, Color.blue],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                            .frame(width: 60, height: 60)
                                        
                                        Image(systemName: "plus")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                ForEach(users, id: \.self) { user in
                                    NavigationLink(destination: CardDetailView(card: createBankCard(for: user))) {
                                        BankCardView(card: createBankCard(for: user))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                        .sheet(isPresented: $showCreateCard) {
                            CreateCardView()
                        }

                        
                        // Действия
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                Button { showSendMoney = true } label: {
                                    ActionButtonView(icon: "paperplane.fill", title: "Отправить", color: Color.blue)
                                }
                                
                                Button { showReceiveMoney = true } label: {
                                    ActionButtonView(icon: "tray.and.arrow.down.fill", title: "Получить", color: Color.green)
                                }
                                
                                Button { isActionButtonView = true } label: {
                                    ActionButtonView(icon: "qrcode.viewfinder", title: "Сканировать", color: Color.purple)
                                }
                                
                                Button { isMoreActionsPresented = true } label: {
                                    ActionButtonView(icon: "ellipsis", title: "Ещё", color: Color.orange)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .fullScreenCover(isPresented: $showSendMoney) { SendMoneyView() }
                        .fullScreenCover(isPresented: $showReceiveMoney) { ReceiveMoneyView() }
                        .fullScreenCover(isPresented: $isActionButtonView) { QRScannerView() }
                        .fullScreenCover(isPresented: $isMoreActionsPresented) { MoreActionsView() }

                        // История операций
                        TransactionHistoryView()
                    }
                }
            }
        }
    }
}

// Остальные структуры (BankCardView, ActionButtonView, TransactionHistoryView и т.д.) остаются без изменений
// MARK: - Компоненты TabBar
struct CustomTabBar: View {
    @Binding var selectedTab: MainTabView.Tab

    var body: some View {
        // ❗️Скрываем весь TabBar, если выбран Terminals
        if selectedTab != .terminals && selectedTab != .cards && selectedTab != .profile{
            VStack {
                Spacer()
                
                HStack {
                    tabBarButton(tab: .home, systemImage: "house.fill", label: "Главная")
                    tabBarButton(tab: .terminals, systemImage: "map.fill", label: "Терминалы")
                    tabBarButton(tab: .cards, systemImage: "lock.shield.fill", label: "Вклад")
                    tabBarButton(tab: .profile, systemImage: "person.fill", label: "Профиль")
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 30)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "B2F7FF").opacity(0.6),
                            Color(hex: "5E60BB").opacity(0.6),
                            Color(hex: "B2F7FF").opacity(0.6)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .cornerRadius(28)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }

    private func tabBarButton(tab: MainTabView.Tab, systemImage: String, label: String) -> some View {
        Button(action: {
            selectedTab = tab
        }) {
            VStack {
                Image(systemName: systemImage)
                    .font(.system(size: 20))
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
            .padding(.horizontal, 10)
        }
    }
}
struct BankCardView: View {
    let card: BankCard

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Фон: либо изображение, либо градиент
            Group {
                if let image = card.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [card.gradientStart, card.gradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(width: 300, height: 160)
            .clipped()
            .cornerRadius(20)
            .overlay(
                VStack(alignment: .leading, spacing: 10) {
                    Text(card.balance)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    Text(card.info)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    HStack {
                        Text(card.number)
                        Spacer()
                        Text(card.expiry)
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding(20)
            )
            .shadow(radius: 5)

            // Кнопка "Пополнить"
            Text("Пополнить")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
                .padding(10)
        }
    }
}


struct ActionButtonView: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(width: 80, height: 100)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            color.opacity(0.3),
                            color.opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}





// MARK: - Расширения
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
// MARK: - Preview
#Preview {
    MainTabView()
}
