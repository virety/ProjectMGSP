//
//  RootView.swift
//  BankApp
//
//  Created by Вадим Семибратов on 02.06.2025.
//

import SwiftUI

struct RootView: View {
    @State private var isAuthenticated = false

    var body: some View {
        Group {
            if isAuthenticated {
                MainTabView()
            } else {
                HomeView(isAuthenticated: $isAuthenticated)
            }
        }
    }
}
