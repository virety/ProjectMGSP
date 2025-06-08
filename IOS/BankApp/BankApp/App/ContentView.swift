//
//  ContentView.swift
//  BankApp
//
//  Created by Вадим Семибратов on 01.06.2025.
//
import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated = false

    var body: some View {
        HomeView(isAuthenticated: $isAuthenticated)
    }
}

#Preview {
    ContentView()
}
