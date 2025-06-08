//
//  SplashView.swift
//  BankApp
//
//  Created by Вадим Семибратов on 07.06.2025.
//

import SwiftUI

struct Star: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var speed: Double
}

struct SplashView: View {
    @State private var stars: [Star] = []
    @State private var animationTimer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    
    private let starCount = 100
    @State private var logoPulse = false
    @State private var hasInitialized = false
    
    var body: some View {
        ZStack {
            // Градиентный фон
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.blue.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            GeometryReader { geo in
                ZStack {
                    ForEach(stars) { star in
                        Circle()
                            .fill(Color.white)
                            .frame(width: star.size, height: star.size)
                            .position(x: star.x, y: star.y)
                            .opacity(0.8)
                            .blur(radius: 0.5)
                    }
                }
                .onAppear {
                    // Инициализация звёзд только один раз после получения размера
                    if !hasInitialized {
                        hasInitialized = true
                        initializeStars(in: geo.size)
                    }
                }
                .onReceive(animationTimer) { _ in
                    updateStars(in: geo.size)
                }
            }
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 160, height: 160)
                        .blur(radius: 30)
                        .scaleEffect(logoPulse ? 1.1 : 0.9)
                        .animation(.easeInOut(duration: 2).repeatForever(), value: logoPulse)
                    
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .shadow(color: .white.opacity(0.8), radius: 10)
                }
                .onAppear {
                    logoPulse = true
                }

                Text("Nyota Bank")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.7), radius: 4)
            }
            .frame(maxHeight: .infinity, alignment: .top) // Прижимаем вверх
            .padding(.top, UIScreen.main.bounds.height * 0.3) // Отступ сверху (примерно 20% экрана)

        }
    }
    
    private func initializeStars(in size: CGSize) {
        stars = (0..<starCount).map { _ in
            Star(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 1...3),
                speed: Double.random(in: 30...120)
            )
        }
    }
    
    private func updateStars(in size: CGSize) {
        let deltaTime = 0.016
        
        for i in stars.indices {
            var star = stars[i]
            star.x += CGFloat(star.speed * deltaTime)
            star.y += CGFloat(star.speed * deltaTime * 0.2)
            
            if star.x > size.width || star.y > size.height {
                star.x = CGFloat.random(in: -20...0)
                star.y = CGFloat.random(in: 0...size.height)
                star.size = CGFloat.random(in: 1...3)
                star.speed = Double.random(in: 30...120)
            }
            
            stars[i] = star
        }
    }
}
