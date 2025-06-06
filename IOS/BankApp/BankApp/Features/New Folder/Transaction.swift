//
//  Transaction.swift
//  BankApp
//
//  Created by Вадим Семибратов on 06.06.2025.
//

import SwiftUI
import CoreData
// MARK: - Основные модели данных
enum TransactionType {
    case income    // Поступление
    case expense   // Списание
    case transfer  // Перевод
}
struct FinancialTransaction: Identifiable {
    var id = UUID()
    let type: TransactionType
    let title: String
    let date: String
    let amount: String
}
// MARK: - Другие экраны
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


struct TransactionsListView: View {
    @FetchRequest(
        entity: CDTransaction.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CDTransaction.date, ascending: false)]
    ) private var cdTransactions: FetchedResults<CDTransaction>

    var transactions: [FinancialTransaction] {
        cdTransactions.map { FinancialTransaction(cdTransaction: $0) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
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
}

extension CDTransaction {
    var transactionType: TransactionType {
        get {
            switch type {
            case 0: return .income
            case 1: return .expense
            case 2: return .transfer
            default: return .expense
            }
        }
        set {
            switch newValue {
            case .income: type = 0
            case .expense: type = 1
            case .transfer: type = 2
            }
        }
    }
}
extension FinancialTransaction {
    init(cdTransaction: CDTransaction) {
        self.id = cdTransaction.id ?? UUID()
        self.type = cdTransaction.transactionType
        self.title = cdTransaction.title ?? "Без названия"
        
        // Форматируем дату в строку
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        if let date = cdTransaction.date {
            self.date = formatter.string(from: date)
        } else {
            self.date = ""
        }
        
        // Форматируем сумму с плюсом или минусом и рублем
        let sign = cdTransaction.amount >= 0 ? "+" : "-"
        let absAmount = String(format: "%0.2f", abs(cdTransaction.amount))
        self.amount = "\(sign)₽\(absAmount)"
    }
}




