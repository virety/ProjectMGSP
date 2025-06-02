import SwiftUI

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
            .edgesIgnoringSafeArea(.all)
            // TabView поверх градиента
            TabView(selection: $selectedTab) {
                BankView()
                    .tabItem {
                        Label("Главная", systemImage: "house.fill")
                    }
                    .tag(Tab.home)
                TransactionsView()
                    .tabItem {
                        Label("Операции", systemImage: "arrow.left.arrow.right")
                    }
                    .tag(Tab.transactions)
                CardsView()
                    .tabItem {
                        Label("Карта", systemImage: "creditcard.fill")
                    }
                    .tag(Tab.cards)
                ProfileView()
                    .tabItem {
                        Label("Профиль", systemImage: "person.fill")
                    }
                    .tag(Tab.profile)
            }
            .tint(.blue)
        }
    }
}

// Расширение для создания Color из hex-строки
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
struct Card: Identifiable {
    let id = UUID()
    let balance: String
    let info: String
    let number: String
    let expiry: String
    let gradientStart: Color
    let gradientEnd: Color
}

struct BankView: View {
    @State private var showAIView = false


    let sampleCards: [Card] = [
        Card(
            balance: "₽16,567.00",
            info: "+3.5% с прошлого месяца",
            number: "**** 1214",
            expiry: "02/25",
            gradientStart: Color(red: 0.24, green: 0.18, blue: 0.91),   // синий
            gradientEnd: Color(red: 0.70, green: 0.28, blue: 1.00)      // фиолетово-розовый
        ),
        Card(
            balance: "₽8,432.50",
            info: "+1.2% с прошлого месяца",
            number: "**** 9856",
            expiry: "11/26",
            gradientStart: Color(red: 0.25, green: 0.55, blue: 0.95),   // голубой
            gradientEnd: Color(red: 0.47, green: 0.30, blue: 0.89)      // фиолетовый
        ),
        Card(
            balance: "₽22,000.00",
            info: "Новая карта",
            number: "**** 3456",
            expiry: "05/27",
            gradientStart: Color(red: 0.56, green: 0.27, blue: 0.90),   // сиреневый
            gradientEnd: Color(red: 0.94, green: 0.33, blue: 0.93)      // розовый
        )
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
                            Button {
                                showAIView = true
                            } label: {
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
                                        ZStack(alignment: .topTrailing) {
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(
                                                    LinearGradient(colors: [card.gradientStart, card.gradientEnd],
                                                                   startPoint: .topLeading,
                                                                   endPoint: .bottomTrailing)
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
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Действия
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                NavigationLink { Text("Экран отправки") } label: {
                                    ActionButton(icon: "paperplane.fill", title: "Отправить")
                                }
                                NavigationLink { Text("Экран получения") } label: {
                                    ActionButton(icon: "tray.and.arrow.down.fill", title: "Получить")
                                }
                                NavigationLink { Text("Экран снятия") } label: {
                                    ActionButton(icon: "arrowshape.turn.up.backward.fill", title: "Снять")
                                }
                                NavigationLink { Text("Другие действия") } label: {
                                    ActionButton(icon: "ellipsis", title: "Ещё")
                                }
                            }
                            .padding(.horizontal)
                        }

                        // История операций
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

                            ForEach(0..<4) { _ in
                                TransactionRow()
                            }
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 30)
                    }
                }

                // Скрытый переход к AIView
                NavigationLink(destination: AIView(), isActive: $showAIView) {
                    EmptyView()
                }
                .hidden()
            }
        }
    }
}



struct ActionButton: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            Text(title)
                .font(.caption)
        }
        .frame(width: 80)
        .padding(8)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct TransactionRow: View {
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Перевод")
                    .font(.subheadline.bold())
                Text("Сегодня 12:30")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("+₽1,500.00")
                .font(.subheadline.bold())
                .foregroundColor(.green)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Заглушки для других вкладок
struct TransactionsView: View {
    var body: some View {
        ScrollView {
            ForEach(0..<20) { _ in
                TransactionRow()
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
        }
        .navigationTitle("Операции")
        .background(Color(.systemGroupedBackground))
    }
}

struct CardsView: View {
    var body: some View {
        Text("Экран карт")
            .navigationTitle("Карты")
    }
}

struct ProfileView: View {
    var body: some View {
        Text("Экран профиля")
            .navigationTitle("Профиль")
    }
}

// Preview
#Preview {
    MainTabView()
}
