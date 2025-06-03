//
//  Predict.swift
//  BankApp
//
//  Created by Вадим Семибратов on 03.06.2025.
//
import SwiftUI

struct PredictView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showCreatePost = false
    @State private var showPredictTool = false
    let predictions: [Prediction] = [
        Prediction(
            user: User(name: "Алексей Финансов", avatar: "👨‍💼", status: "Эксперт"),
            currency: "USD/RUB",
            prediction: "Доллар вырастет до 95 ₽ к концу месяца из-за повышения ставок ФРС",
            direction: .up,
            confidence: 85,
            date: "15.06.2025",
            likes: 24,
            comments: 5
        ),
        Prediction(
            user: User(name: "Елена Инвестор", avatar: "👩‍💻", status: "Трейдер"),
            currency: "EUR/RUB",
            prediction: "Евро упадет до 90 ₽ после заявлений ЕЦБ о смягчении политики",
            direction: .down,
            confidence: 72,
            date: "14.06.2025",
            likes: 15,
            comments: 3
        ),
        Prediction(
            user: User(name: "Максим Аналитик", avatar: "🧑‍🏫", status: "Аналитик"),
            currency: "SBER",
            prediction: "Акции Сбера могут вырасти на 10% после отчета за квартал",
            direction: .up,
            confidence: 68,
            date: "13.06.2025",
            likes: 42,
            comments: 12
        ),
        Prediction(
            user: User(name: "Ольга Трейдер", avatar: "👩‍💼", status: "Новичок"),
            currency: "GAZP",
            prediction: "Газпром продолжит снижение из-за падения цен на газ в Европе",
            direction: .down,
            confidence: 55,
            date: "12.06.2025",
            likes: 8,
            comments: 2
        )
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
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
                // Кастомный заголовок с кнопками
                headerView()
                
                // Скроллируемый контент
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(predictions) { prediction in
                            PredictionCard(prediction: prediction)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true) // Скрываем стандартный навбар
        .sheet(isPresented: $showCreatePost) {
            CreatePostView()
        }
        .sheet(isPresented: $showPredictTool) {
            PredictToolView()
        }
    }
    
    private func headerView() -> some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .ignoresSafeArea(edges: .top)
                .frame(height: 56)
            
            // Центральный заголовок
            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18))
                Text("Форум прогнозов")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            
            // Кнопки навигации
            HStack {
                // Кнопка назад
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                // Кнопка инструментов прогноза
                Button(action: {
                    showPredictTool = true
                }) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
                
                // Кнопка создания поста
                Button(action: {
                    showCreatePost = true
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 56)
    }
}



// Модели данных
struct User: Identifiable {
    let id = UUID()
    let name: String
    let avatar: String
    let status: String
}

enum PredictionDirection {
    case up, down
}

struct Prediction: Identifiable {
    let id = UUID()
    let user: User
    let currency: String
    let prediction: String
    let direction: PredictionDirection
    let confidence: Int // Уверенность в процентах
    let date: String
    let likes: Int
    let comments: Int
}

// Карточка прогноза
struct PredictionCard: View {
    let prediction: Prediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Заголовок с пользователем
            HStack(alignment: .top) {
                Text(prediction.user.avatar)
                    .font(.system(size: 32))
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(prediction.user.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(prediction.user.status)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Text(prediction.date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Информация о валюте/акции
            HStack {
                Text(prediction.currency)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(prediction.direction == .up ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                    )
                
                Text(prediction.direction == .up ? "Рост" : "Падение")
                    .font(.subheadline)
                    .foregroundColor(prediction.direction == .up ? .green : .red)
                
                Spacer()
                
                Text("\(prediction.confidence)% уверенность")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Текст прогноза
            Text(prediction.prediction)
                .font(.body)
                .foregroundColor(.white)
                .padding(.vertical, 8)
            
            // Действия
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "hand.thumbsup.fill")
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(prediction.likes)")
                        .foregroundColor(.white.opacity(0.7))
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left.fill")
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(prediction.comments)")
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: {}) {
                    Text("Подробнее")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            .font(.caption)
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

struct PredictView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PredictView()
        }
    }
}
