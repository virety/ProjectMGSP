import SwiftUI
import CoreData

struct CreatePostView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var viewContext
    
    @FetchRequest(entity: CDUser.entity(), sortDescriptors: []) var users: FetchedResults<CDUser>
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedAvatar: String = "👩‍💻"
    @State private var selectedStatus: String = "Трейдер"
    
    @State private var leftCurrency: String = "EUR"
    @State private var rightCurrency: String = "RUB"
    
    @State private var predictionText: String = ""
    @State private var direction: Direction = .up
    @State private var confidence: Double = 70
    @State private var date: Date = Date()
    @State private var showConfirmation = false
    
    let availableAvatars = ["👩‍💻", "🧑‍💼", "🧠", "📊", "💹"]
    let availableStatuses = ["Трейдер", "Аналитик", "Брокер", "Эксперт"]
    let availableCurrencies = ["USD", "EUR", "RUB", "CNY", "JPY", "GBP"]
    
    var availableRightCurrencies: [String] {
        availableCurrencies.filter { $0 != leftCurrency }
    }
    var availableLeftCurrencies: [String] {
        availableCurrencies.filter { $0 != rightCurrency }
    }
    
    var currencyPair: String {
        "\(leftCurrency)/\(rightCurrency)"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    var currentUser: CDUser? {
        users.first
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.06, green: 0.04, blue: 0.15),
                    Color(red: 0.15, green: 0.08, blue: 0.35),
                    Color(red: 0.25, green: 0.13, blue: 0.45)
                ]),
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Group {
                        sectionHeader("Пользователь")
                        
                        if let user = currentUser {
                            Text("\(user.firstName ?? "") \(user.lastName ?? "")")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.leading, 16)
                        } else {
                            Text("Нет пользователя")
                                .foregroundColor(.red)
                                .padding(.leading, 16)
                        }
                        
                        pickerWithLabel("Аватар", selection: $selectedAvatar, options: availableAvatars)
                        pickerWithLabel("Статус", selection: $selectedStatus, options: availableStatuses)
                    }
                    
                    Group {
                        sectionHeader("Прогноз")
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Валютная пара")
                                .foregroundColor(.white.opacity(0.7))
                            
                            HStack {
                                Picker("Левая", selection: $leftCurrency) {
                                    ForEach(availableLeftCurrencies, id: \.self) { Text($0) }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity)
                                .tint(.white)
                                .onChange(of: leftCurrency) { newLeft in
                                    if rightCurrency == newLeft {
                                        rightCurrency = availableRightCurrencies.first ?? rightCurrency
                                    }
                                }
                                
                                Button(action: {
                                    swap(&leftCurrency, &rightCurrency)
                                }) {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.white.opacity(0.15))
                                        .cornerRadius(8)
                                }
                                
                                Picker("Правая", selection: $rightCurrency) {
                                    ForEach(availableRightCurrencies, id: \.self) { Text($0) }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity)
                                .tint(.white)
                                .onChange(of: rightCurrency) { newRight in
                                    if leftCurrency == newRight {
                                        leftCurrency = availableLeftCurrencies.first ?? leftCurrency
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Направление")
                                .foregroundColor(.white.opacity(0.7))
                            Picker("Направление", selection: $direction) {
                                Text("⬆️ Вверх").tag(Direction.up)
                                Text("⬇️ Вниз").tag(Direction.down)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .colorMultiply(direction == .up ? .green : .red)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Описание прогноза")
                                .foregroundColor(.white.opacity(0.7))
                            TextEditor(text: $predictionText)
                                .frame(height: 120)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .scrollContentBackground(.hidden)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Уверенность: \(Int(confidence))%")
                                .foregroundColor(.white.opacity(0.7))
                            Slider(value: $confidence, in: 0...100)
                                .accentColor(direction == .up ? .green : .red)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Дата прогноза")
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .center) // Заголовок по центру, опционально

                            HStack {
                                Spacer()

                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.08))

                                    Text(formattedDate)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .frame(height: 40)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                                .frame(height: 40)
                                .frame(maxWidth: 250) // Ограничьте ширину, чтобы не растягивалось на весь экран

                                Spacer()
                            }
                        }
                        
                        Button(action: savePost) {
                            Label("Опубликовать прогноз", systemImage: "paperplane.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .onAppear { // 👈 ДОБАВЛЕНО onAppear
                if let user = currentUser {
                    selectedAvatar = user.avatar ?? selectedAvatar
                    selectedStatus = user.status ?? selectedStatus
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Новая статья")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
            .alert("Прогноз опубликован!", isPresented: $showConfirmation) {
                Button("Ок", role: .cancel) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func savePost() {
        guard let user = currentUser else { return }
        
        let post = CDPost(context: viewContext)
        post.id = UUID()
        post.date = date
        post.direction = direction.rawValue
        post.confidence = confidence
        post.predictionText = predictionText
        post.leftCurrency = leftCurrency
        post.rightCurrency = rightCurrency
        post.user = user
        post.avatar = selectedAvatar
        post.status = selectedStatus

        
        do {
            try viewContext.save()
            showConfirmation = true
        } catch {
            print("Ошибка сохранения: \(error.localizedDescription)")
        }
    }
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.title3)
            .bold()
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.leading, 16)
    }

    private func pickerWithLabel(_ title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .foregroundColor(.white.opacity(0.7))
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { Text($0) }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)
            .foregroundColor(.white)
        }
        .padding(.horizontal)
    }
}

enum Direction: String, CaseIterable, Identifiable {
    case up, down
    var id: String { rawValue }
}
