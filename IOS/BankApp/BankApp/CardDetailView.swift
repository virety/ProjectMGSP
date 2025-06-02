//
//  CardView.swift
//  BankApp
//
//  Created by Вадим Семибратов on 02.06.2025.
//

import SwiftUI

struct CardDetailView: View {
    let card: Card

    var body: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: [card.gradientStart, card.gradientEnd],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 160)
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
                .padding()

            Spacer()
        }
        .navigationTitle("Карта")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}
