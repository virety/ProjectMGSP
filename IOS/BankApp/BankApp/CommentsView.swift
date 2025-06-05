//
//  CommentsView.swift
//  BankApp
//
//  Created by Вадим Семибратов on 05.06.2025.
//

import SwiftUI
import CoreData

struct CommentsView: View {
    let postId: NSManagedObjectID
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var newCommentText = ""
    @State private var comments: [CDComment] = []
    
    let currentUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
    
    var body: some View {
        VStack {
            HStack {
                Button("Закрыть") { dismiss() }
                    .foregroundColor(.blue)
                Spacer()
            }

            Text("Комментарии")
                .font(.title2)
                .bold()
                .padding(.vertical)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    let commentArray: [CDComment] = comments
                }
            }

            Divider()

            HStack {
                TextField("Добавить комментарий...", text: $newCommentText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Опубликовать") {
                    addComment()
                }
                .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.bottom, 8)
        }
        .padding()
        .onAppear(perform: loadComments)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func loadComments() {
        do {
            if let post = try viewContext.existingObject(with: postId) as? CDPost {
                if let commentSet = post.comments as? Set<CDComment> {
                    let sortedComments = commentSet.sorted {
                        ($0.dateCreated ?? Date.distantPast) < ($1.dateCreated ?? Date.distantPast)
                    }
                    comments = sortedComments
                }
            }
        } catch {
            print("Ошибка загрузки комментариев: \(error)")
        }
    }

    private func addComment() {
        let trimmedText = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        do {
            if let post = try viewContext.existingObject(with: postId) as? CDPost {
                let comment = CDComment(context: viewContext)
                comment.text = trimmedText
                let now = Date()
                comment.dateCreated = now
                comment.post = post

                if let user = fetchOrCreateUser(id: currentUserId) {
                    comment.user = user
                }

                try viewContext.save()
                newCommentText = ""
                loadComments()
            }
        } catch {
            print("Ошибка добавления комментария: \(error)")
        }
    }

    private func fetchOrCreateUser(id: UUID) -> CDUser? {
        let request = CDUser.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            let users = try viewContext.fetch(request)
            if let user = users.first {
                return user
            } else {
                let newUser = CDUser(context: viewContext)
                newUser.setValue(id, forKey: "id") // Избегаем прямого доступа к `id`, т.к. он может быть readonly
                newUser.firstName = "Текущий"
                newUser.lastName = "Пользователь"
                newUser.avatar = "👤"
                newUser.status = "Гость"
                try viewContext.save()
                return newUser
            }
        } catch {
            print("Ошибка создания/получения пользователя: \(error)")
            return nil
        }
    }
}
