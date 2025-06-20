import CoreData
import SwiftUI

struct CreateCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: CDUser.entity(),
        sortDescriptors: [],
        predicate: NSPredicate(format: "isAuthenticated == YES")
    ) private var authenticatedUsers: FetchedResults<CDUser>
    
    @State private var cardName = ""
    @State private var cardNumber = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let issueDate = Date()
    private let expiryDate: Date = {
        let calendar = Calendar.current
        return calendar.date(byAdding: .year, value: 4, to: Date()) ?? Date()
    }()
    
    private var issueDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        return formatter.string(from: issueDate)
    }
    
    private var expiryDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        return formatter.string(from: expiryDate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
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
                        contentView
                            .padding()
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                cardNumber = generateCardNumber()
            }
            .alert("Ошибка", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func headerView() -> some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .ignoresSafeArea(edges: .top)
                .frame(height: 56)
            
            Text("Новая карта")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            HStack {
                Button(action: { dismiss() }) {
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

    private var contentView: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Название карты")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.headline)
                
                TextField("Введите название карты", text: $cardName)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .autocapitalization(.words)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("Данные карты")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.headline)
                
                labeledInfo(title: "Номер карты", value: cardNumber)
                labeledInfo(title: "Дата выпуска", value: issueDateString)
                labeledInfo(title: "Срок действия", value: expiryDateString)
            }

            Button(action: createCard) {
                Text("Создать карту")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue.opacity(0.7) : Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!isFormValid)
        }
    }

    private func labeledInfo(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .foregroundColor(.white.opacity(0.8))
    }

    private var isFormValid: Bool {
        !cardName.isEmpty
    }

    private func generateCardNumber() -> String {
        var number = String(Int.random(in: 1...9))
        for _ in 1..<16 {
            number += String(Int.random(in: 0...9))
        }
        return number.chunked(into: 4).joined(separator: " ")
    }

    private func createCard() {
        guard let user = authenticatedUsers.first else {
            showError = true
            errorMessage = "Не удалось найти авторизованного пользователя"
            return
        }
        
        // Create a new Card entity
        let newCard = Card(context: viewContext)
        newCard.cardName = cardName
        newCard.cardNumber = cardNumber.replacingOccurrences(of: " ", with: "")
        newCard.cardExpiry = expiryDate
        newCard.cardIssueDate = issueDate
        newCard.balance = 0
        newCard.owner = user
        
        // Update user's card info to match the new card
        user.cardName = cardName
        user.cardNumber = cardNumber.replacingOccurrences(of: " ", with: "")
        user.cardExpiry = expiryDate
        user.cardIssueDate = issueDate
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            showError = true
            errorMessage = "Ошибка при создании карты: \(error.localizedDescription)"
        }
    }
}

// MARK: - Utility extension for formatting card number
extension String {
    func chunked(into size: Int) -> [String] {
        stride(from: 0, to: count, by: size).map {
            let start = index(startIndex, offsetBy: $0)
            let end = index(start, offsetBy: size, limitedBy: endIndex) ?? endIndex
            return String(self[start..<end])
        }
    }
}
