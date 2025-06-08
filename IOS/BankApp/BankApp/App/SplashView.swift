//
//  SplashView.swift
//  BankApp
//
//  Created by Вадим Семибратов on 07.06.2025.
//

import SwiftUI

// Модель звезды с уникальным id, позицией, размером и скоростью
struct Star: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var speed: Double
}

struct SplashView: View {
    // Массив звёзд
    @State private var stars: [Star] = []
    // Таймер для обновления анимации
    @State private var animationTimer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()

    // Количество звёзд
    private let starCount = 80

    var body: some View {
        ZStack {
            // Фон - чёрное звездное небо
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            GeometryReader { geo in
                // Отрисовка звезд
                ForEach(stars) { star in
                    Circle()
                        .fill(Color.white)
                        .frame(width: star.size, height: star.size)
                        .position(x: star.x, y: star.y)
                        .opacity(0.8)
                }
                // Обновление позиций звезд каждую итерацию таймера
                .onReceive(animationTimer) { _ in
                    updateStars(in: geo.size)
                }
                // Инициализация звезд при появлении вью
                .onAppear {
                    initializeStars(in: geo.size)
                }
            }
            
            // Логотип и приветственный текст поверх звезд
            VStack(spacing: 20) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.7), radius: 10, x: 0, y: 0)
                
                Text("Nyota bank")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.7), radius: 4, x: 0, y: 0)
            }
            .padding(.top, 100)
        }
    }

    // Инициализация массива звезд с рандомными параметрами
    private func initializeStars(in size: CGSize) {
        stars = (0..<starCount).map { _ in
            Star(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 1...3),
                speed: Double.random(in: 20...100)
            )
        }
    }

    // Обновление позиции звезд с движением слева направо
    private func updateStars(in size: CGSize) {
        let deltaTime = 0.02 // интервал таймера
        
        for i in stars.indices {
            var star = stars[i]
            star.x += CGFloat(star.speed * deltaTime)
            
            // Если звезда вышла за правый край, переносим её налево с новыми параметрами
            if star.x > size.width {
                star.x = 0
                star.y = CGFloat.random(in: 0...size.height)
                star.size = CGFloat.random(in: 1...3)
                star.speed = Double.random(in: 20...100)
            }
            
            stars[i] = star
        }
    }
}
