//
//  Predict.swift
//  BankApp
//
//  Created by Вадим Семибратов on 03.06.2025.
//
import SwiftUI
import CoreData

struct PredictView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showCreatePost = false
    @State private var showPredictTool = false

    @FetchRequest(
        entity: CDPost.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CDPost.date, ascending: false)]
    ) var coreDataPosts: FetchedResults<CDPost>

    var predictions: [Prediction] {
        coreDataPosts.compactMap { post in
            guard let directionRaw = post.direction,
                  let direction = PredictionDirection(rawValue: directionRaw),
                  let date = post.date,
                  let left = post.leftCurrency,
                  let right = post.rightCurrency,
                  let text = post.predictionText else {
                return nil
            }

            let user = User(
                name: "\(post.user?.firstName ?? "") \(post.user?.lastName ?? "")",
                avatar: post.avatar ?? "👤",
                status: post.status ?? "Гость"
            )


            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy"
            let formattedDate = formatter.string(from: date)

            return Prediction(
                user: user,
                currency: "\(left)/\(right)",
                prediction: text,
                direction: direction,
                confidence: Int(post.confidence),
                date: formattedDate,
                likes: 0,
                comments: 0
            )
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
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
                headerView()

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
        .navigationBarHidden(true)
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

            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18))
                Text("Форум прогнозов")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)

            HStack {
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

// MARK: - Модели

struct User: Identifiable {
    let id = UUID()
    let name: String
    let avatar: String
    let status: String
}

enum PredictionDirection: String {
    case up, down
}

struct Prediction: Identifiable {
    let id = UUID()
    let user: User
    let currency: String
    let prediction: String
    let direction: PredictionDirection
    let confidence: Int
    let date: String
    let likes: Int
    let comments: Int
}

// MARK: - Карточка прогноза
struct PredictionCard: View {
    let prediction: Prediction

    @State private var likes: Int
    @State private var comments: Int

    init(prediction: Prediction) {
        self.prediction = prediction
        _likes = State(initialValue: prediction.likes)
        _comments = State(initialValue: prediction.comments)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            Text(prediction.prediction)
                .font(.body)
                .foregroundColor(.white)
                .padding(.vertical, 8)

            HStack {
                Button(action: {
                    likes += 1
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.thumbsup.fill")
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(likes)")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Button(action: {
                    comments += 1
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.fill")
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(comments)")
                            .foregroundColor(.white.opacity(0.7))
                    }
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

