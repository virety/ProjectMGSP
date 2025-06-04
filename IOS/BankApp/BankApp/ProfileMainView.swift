//
//  ProfileMainView.swift
//  BankApp
//
//  Created by Вадим Семибратов on 03.06.2025.
//
import SwiftUI
import PhotosUI

struct ProfileMainView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedTab: MainTabView.Tab
    @State private var showLogin = false
    @State private var showLogoutConfirm = false
    @State private var showPinPad = false
    @State private var enteredPin = ""
    @State private var correctPin = "1234" // 🔐 Настоящий PIN

    
    @State private var depositsCount = 2
    @State private var depositsSum: Double = 15768
    @State private var depositsPercent: Double = 3.04
    
    @State private var creditsCount = 1
    @State private var creditsRemainingDebt: Double = 32000
    
    @State private var nextPaymentDate = "17 мая"
    @State private var nextPaymentAmount: Double = 2000
    
    @State private var mortgagesCount = 0
    
    @State private var profileImage: Image? = nil
    @State private var selectedItem: PhotosPickerItem? = nil
    
    var body: some View {
        ZStack {
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
                // Верхний toolbar
                headerView()
                
                // Основное содержимое
                ScrollView {
                    VStack(spacing: 20) {
                        // Фото профиля
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            if let profileImage = profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.top, 20)
                        
                        // ФИО
                        Text("Семибратов Вадим Викторович")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        // Единая таблица продуктов
                        VStack(spacing: 0) {
                            // Секция вкладов
                            HStack {
                                Text("Вклады")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(depositsCount)")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("+\(formatCurrency(depositsSum)) ₽")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text(String(format: "%.2f%%", depositsPercent))
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 16)
                            
                            // Разделитель
                            Divider()
                                .background(Color.white.opacity(0.2))
                                .padding(.horizontal, 16)
                            
                            // Секция кредитов и платежей
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Кредиты")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(creditsCount)")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                HStack {
                                    Text("Остаток долга")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(formatCurrency(creditsRemainingDebt)) ₽")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                }
                                
                                HStack {
                                    Text("Ближайший платёж")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text(nextPaymentDate)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                        Text("-\(formatCurrency(nextPaymentAmount)) ₽")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            
                            // Разделитель
                            Divider()
                                .background(Color.white.opacity(0.2))
                                .padding(.horizontal, 16)
                            
                            // Секция ипотеки
                            HStack {
                                Text("Ипотека")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(mortgagesCount)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 16)
                        }
                        .background(
                            Color.white.opacity(0.1)
                                .cornerRadius(12)
                        )
                        .padding(.horizontal)
                        
                        Button(action: {
                            showLogoutConfirm = true
                        }) {
                            Text("Выйти")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                        .confirmationDialog("Вы уверены, что хотите выйти?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                            Button("Выйти", role: .destructive) {
                                showPinPad = true
                            }
                            Button("Отмена", role: .cancel) {}
                        }
                        .fullScreenCover(isPresented: $showLogin) {
                            HomeView(isAuthenticated: .constant(false))
                        }

                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: selectedItem) { _ in loadImage() }
    }
    
    private func headerView() -> some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .ignoresSafeArea(edges: .top)
                .frame(height: 56)
            
            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .font(.system(size: 18))
                Text("Профиль")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            
            HStack {
                Button(action: {
                    if presentationMode.wrappedValue.isPresented {
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        selectedTab = .home
                    }
                }) {
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
    
    private func loadImage() {
        Task {
            guard let data = try? await selectedItem?.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else { return }
            profileImage = Image(uiImage: uiImage)
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}
