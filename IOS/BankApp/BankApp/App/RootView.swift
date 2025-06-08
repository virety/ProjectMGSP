//
//  RootView.swift
//  BankApp
//
//  Created by Вадим Семибратов on 02.06.2025.
//

import SwiftUI

struct RootView: View {
    @State private var isAuthenticated = false
    @State private var showSplash = true
    
    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                showSplash = false
                            }
                        }
                    }
            } else {
                if isAuthenticated {
                    MainTabView()
                } else {
                    HomeView(isAuthenticated: $isAuthenticated)
                }
            }
        }
    }
}

