//
//  TransactionHistoryView.swift
//  BankApp
//
//  Created by Вадим Семибратов on 06.06.2025.
//
import CoreData
import SwiftUI
import PhotosUI

struct TransactionHistoryView: View {
    @FetchRequest(
        entity: CDTransaction.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CDTransaction.date, ascending: false)]
    ) private var cdTransactions: FetchedResults<CDTransaction>
    
    var transactions: [FinancialTransaction] {
        cdTransactions.map { FinancialTransaction(cdTransaction: $0) }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("История операций")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                NavigationLink("Смотреть все") {
                    AllTransactionsView(transactions: transactions)
                }
                .font(.subheadline)
            }
            .padding(.horizontal)
            
            // 🔥 Ограничение до 5 транзакций
            ForEach(transactions.prefix(3)) { transaction in
                TransactionRowView(transaction: transaction)
                    .padding(.horizontal)
            }
        }
    }
}
