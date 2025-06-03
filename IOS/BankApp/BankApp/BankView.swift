import SwiftUI

// MARK: - Основные модели данных
enum TransactionType {
    case income    // Поступление
    case expense   // Списание
    case transfer  // Перевод
}

struct BankCard: Identifiable {
    let id = UUID()
    let balance: String
    let info: String
    let number: String
    let expiry: String
    let gradientStart: Color
    let gradientEnd: Color
}

struct FinancialTransaction: Identifiable {
    let id = UUID()
    let type: TransactionType
    let title: String
    let date: String
    let amount: String
}

// MARK: - Главный TabView
struct MainTabView: View {
    enum Tab {
        case home
        case transactions
        case cards
        case profile
    }
    
    @State private var selectedTab: Tab = .home
    
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
            Group {
                switch selectedTab {
                case .home:
                    BankHomeView()
                case .transactions:
                    TransactionsListView()
                case .cards:
                    CardsMainView()
                case .profile:
                    ProfileMainView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Кастомный TabBar
            CustomTabBar(selectedTab: $selectedTab)
        }
    }
}

// MARK: - Компоненты TabBar
struct CustomTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                tabBarButton(tab: .home, systemImage: "house.fill", label: "Главная")
                tabBarButton(tab: .transactions, systemImage: "arrow.left.arrow.right", label: "Операции")
                tabBarButton(tab: .cards, systemImage: "creditcard.fill", label: "Карта")
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

struct TransactionRowView: View {
    let transaction: FinancialTransaction
    
    private var iconName: String {
        switch transaction.type {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch transaction.type {
        case .income: return .green
        case .expense: return .red
        case .transfer: return .blue
        }
    }
    
    private var gradientColors: [Color] {
        switch transaction.type {
        case .income: return [Color.green.opacity(0.3), Color.green.opacity(0.1)]
        case .expense: return [Color.red.opacity(0.3), Color.red.opacity(0.1)]
        case .transfer: return [Color.blue.opacity(0.3), Color.blue.opacity(0.1)]
        }
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(iconColor.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: iconName)
                        .foregroundColor(iconColor)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white) // Сделано белым
                Text(transaction.date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8)) // Сделано белым (чуть тусклее)
            }
            
            Spacer()
            
            Text(formatAmount(transaction.amount))
                .font(.subheadline.bold())
                .foregroundColor(transaction.type == .income ? .green : .red)
        }
        .padding(12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .top,
                endPoint: .bottom // Вертикальный градиент
            )
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // Сначала сумма, потом валюта
    private func formatAmount(_ original: String) -> String {
        // Пример: "+₽45,000" -> "+45,000 ₽"
        let cleaned = original.replacingOccurrences(of: "₽", with: "").trimmingCharacters(in: .whitespaces)
        if original.hasPrefix("+") {
            return "+\(cleaned.dropFirst()) ₽"
        } else if original.hasPrefix("-") {
            return "-\(cleaned.dropFirst()) ₽"
        }
        return "\(cleaned) ₽"
    }
}

struct SendMoneyView: View {
    var body: some View {
        VStack {
            Text("Отправить деньги")
                .font(.title)
            // Дополнительный UI тут
        }
        .navigationTitle("Отправка")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ReceiveMoneyView: View {
    var body: some View {
        VStack {
            Text("Получить деньги")
                .font(.title)
        }
        .navigationTitle("Получение")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WithdrawMoneyView: View {
    var body: some View {
        VStack {
            Text("Снятие наличных")
                .font(.title)
        }
        .navigationTitle("Снятие")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MoreActionsView: View {
    var body: some View {
        VStack {
            Text("Другие действия")
                .font(.title)
        }
        .navigationTitle("Другое")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Bank Home View
struct BankHomeView: View {
    @State private var showAIView = false
    
    let sampleCards: [BankCard] = [
        BankCard(
            balance: "₽16,567.00",
            info: "+3.5% с прошлого месяца",
            number: "**** 1214",
            expiry: "02/25",
            gradientStart: Color(red: 0.24, green: 0.18, blue: 0.91),
            gradientEnd: Color(red: 0.70, green: 0.28, blue: 1.00)
        ),
        BankCard(
            balance: "₽8,432.50",
            info: "+1.2% с прошлого месяца",
            number: "**** 9856",
            expiry: "11/26",
            gradientStart: Color(red: 0.25, green: 0.55, blue: 0.95),
            gradientEnd: Color(red: 0.47, green: 0.30, blue: 0.89)
        ),
        BankCard(
            balance: "₽22,000.00",
            info: "Новая карта",
            number: "**** 3456",
            expiry: "05/27",
            gradientStart: Color(red: 0.56, green: 0.27, blue: 0.90),
            gradientEnd: Color(red: 0.94, green: 0.33, blue: 0.93)
        )
    ]
    
    let transactions = [
        FinancialTransaction(type: .income, title: "Зарплата", date: "Сегодня 10:00", amount: "+₽45,000"),
        FinancialTransaction(type: .expense, title: "Супермаркет", date: "Вчера 18:22", amount: "-₽2,300"),
        FinancialTransaction(type: .transfer, title: "Перевод другу", date: "Сегодня 13:10", amount: "-₽1,500")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Градиентный фон
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
                                Text("Привет, Вадим!")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                Text("Как дела сегодня?")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            Spacer()
                            
                            // NavigationLink вместо Button
                            NavigationLink(destination: AIView()) {
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
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)

                        // Карты
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(sampleCards) { card in
                                    NavigationLink(destination: CardDetailView(card: card)) {
                                        BankCardView(card: card)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Действия
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                NavigationLink {
                                    SendMoneyView()
                                } label: {
                                    ActionButtonView(icon: "paperplane.fill",
                                                    title: "Отправить",
                                                    color: Color.blue)
                                }
                                .buttonStyle(PlainButtonStyle())

                                NavigationLink {
                                    ReceiveMoneyView()
                                } label: {
                                    ActionButtonView(icon: "tray.and.arrow.down.fill",
                                                    title: "Получить",
                                                    color: Color.green)
                                }
                                .buttonStyle(PlainButtonStyle())

                                NavigationLink {
                                    WithdrawMoneyView()
                                } label: {
                                    ActionButtonView(icon: "arrowshape.turn.up.backward.fill",
                                                    title: "Снять",
                                                    color: Color.purple)
                                }
                                .buttonStyle(PlainButtonStyle())

                                NavigationLink {
                                    MoreActionsView()
                                } label: {
                                    ActionButtonView(icon: "ellipsis",
                                                    title: "Ещё",
                                                    color: Color.orange)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal)
                        }

                        // История операций
                        TransactionHistoryView(transactions: transactions)
                        
                        Spacer(minLength: 30)
                    }
                }
            }
        }
    }
}

// MARK: - Дополнительные компоненты
struct BankCardView: View {
    let card: BankCard
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [card.gradientStart, card.gradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 300, height: 160)
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

struct TransactionHistoryView: View {
    let transactions: [FinancialTransaction]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("История операций")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                NavigationLink("Смотреть все") {
                    Text("Все операции")
                }
                .font(.subheadline)
            }
            .padding(.horizontal)
            
            ForEach(transactions) { transaction in
                TransactionRowView(transaction: transaction)
                    .padding(.horizontal)
            }
        }
    }
}

// MARK: - Другие экраны


struct TransactionsListView: View {
    let transactions = [
        FinancialTransaction(type: .income, title: "Зарплата", date: "Сегодня 10:00", amount: "+₽45,000"),
        FinancialTransaction(type: .expense, title: "Супермаркет", date: "Вчера 18:22", amount: "-₽2,300"),
        FinancialTransaction(type: .transfer, title: "Перевод другу", date: "Сегодня 13:10", amount: "-₽1,500"),
        FinancialTransaction(type: .income, title: "Кэшбэк", date: "30 мая", amount: "+₽320"),
        FinancialTransaction(type: .expense, title: "Кофейня", date: "30 мая", amount: "-₽260"),
    ]
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea() // 👈 Это главное — фон на весь экран

            ScrollView {
                ForEach(transactions) { transaction in
                    TransactionRowView(transaction: transaction)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Операции")
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
