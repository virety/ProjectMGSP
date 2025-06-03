//
//  TerminalView.swift
//  BankApp
//
//  Created by Вадим Семибратов on 03.06.2025.
//

import SwiftUI
import MapKit

struct Terminal: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let distance: String
    let isATM: Bool
    let coordinates: CLLocationCoordinate2D
}

struct TerminalsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedTab: MainTabView.Tab
    @State private var selectedTerminalID: UUID? = nil
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.1155, longitude: 131.8855),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    
    // Теперь terminals — @State для обновления
    @State private var terminals: [Terminal] = [
        Terminal(name: "Терминал №8", address: "ул. Центральная, 10, Артем", distance: "12.5 км", isATM: false, coordinates: CLLocationCoordinate2D(latitude: 43.3890, longitude: 132.1900)),
        Terminal(name: "Терминал №3", address: "ул. Пушкинская, 20, Владивосток", distance: "0.5 км", isATM: true, coordinates: CLLocationCoordinate2D(latitude: 43.1189, longitude: 131.8812)),
        Terminal(name: "Терминал №1", address: "ул. Светланская, 1, Владивосток", distance: "0.2 км", isATM: true, coordinates: CLLocationCoordinate2D(latitude: 43.1168, longitude: 131.8875)),
        Terminal(name: "Терминал №11", address: "ул. Гагарина, 12, Артем", distance: "14.5 км", isATM: true, coordinates: CLLocationCoordinate2D(latitude: 43.3920, longitude: 132.1960)),
        Terminal(name: "Терминал №5", address: "ул. Тигровая, 10, Владивосток", distance: "0.8 км", isATM: true, coordinates: CLLocationCoordinate2D(latitude: 43.1125, longitude: 131.8860)),
        Terminal(name: "Терминал №10", address: "ул. Советская, 7, Артем", distance: "14.0 км", isATM: false, coordinates: CLLocationCoordinate2D(latitude: 43.3915, longitude: 132.1950)),
        Terminal(name: "Терминал №4", address: "ул. Адмирала Фокина, 8, Владивосток", distance: "0.6 км", isATM: false, coordinates: CLLocationCoordinate2D(latitude: 43.1150, longitude: 131.8850)),
        Terminal(name: "Терминал №7", address: "ул. Лазо, 3, Артем", distance: "12.0 км", isATM: true, coordinates: CLLocationCoordinate2D(latitude: 43.3870, longitude: 132.1870)),
        Terminal(name: "Терминал №9", address: "ул. Пушкина, 5, Артем", distance: "13.0 км", isATM: true, coordinates: CLLocationCoordinate2D(latitude: 43.3905, longitude: 132.1935)),
        Terminal(name: "Терминал №2", address: "ул. Алеутская, 15, Владивосток", distance: "0.4 км", isATM: false, coordinates: CLLocationCoordinate2D(latitude: 43.1175, longitude: 131.8831)),
        Terminal(name: "Терминал №6", address: "пр. Красного Знамени, 25, Владивосток", distance: "1.0 км", isATM: false, coordinates: CLLocationCoordinate2D(latitude: 43.1210, longitude: 131.8899)),
    ]

    
    var body: some View {
        ZStack {
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
                headerView()
                
                Map(coordinateRegion: $region, annotationItems: terminals) { terminal in
                    MapAnnotation(coordinate: terminal.coordinates) {
                        VStack {
                            Image(systemName: terminal.isATM ? "banknote" : "creditcard.fill")
                                .padding(8)
                                .background(
                                    terminal.id == selectedTerminalID ? Color.green : Color.blue
                                )
                                .foregroundColor(.white)
                                .clipShape(Circle())
                            Text(terminal.name)
                                .font(.caption)
                                .fixedSize()
                        }
                    }
                }
                .frame(height: 300)
                .cornerRadius(12)
                .padding()
                
                List(terminals) { terminal in
                    Button(action: {
                        selectedTerminalID = terminal.id
                        withAnimation {
                            region = MKCoordinateRegion(
                                center: terminal.coordinates,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(terminal.name)
                                    .font(.headline)
                                Text(terminal.address)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(terminal.distance)
                                    .font(.subheadline)
                                Image(systemName: terminal.isATM ? "banknote" : "creditcard.fill")
                                    .foregroundColor(terminal.isATM ? .green : .blue)
                            }
                        }
                        .padding(.vertical, 8)
                        .background(
                            selectedTerminalID == terminal.id
                                ? Color.blue.opacity(0.1)
                                : Color.clear
                        )
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                .listStyle(PlainListStyle())
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .padding([.horizontal, .bottom])
                
                // Кнопка снизу под списком
                Button(action: sortTerminalsByDistance) {
                    Text("Найти ближайший терминал")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .padding([.horizontal, .bottom])
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func headerView() -> some View {
            ZStack {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .ignoresSafeArea(edges: .top)
                    .frame(height: 56)
                
                HStack(spacing: 6) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 18))
                    Text("Терминалы")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                
                HStack {
                    Button(action: {
                        // Возвращаем на предыдущий экран или на вкладку home
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
    private func sortTerminalsByDistance() {
        terminals.sort {
            $0.distanceValue < $1.distanceValue
        }

        if let nearest = terminals.first {
            selectedTerminalID = nearest.id
            withAnimation {
                region = MKCoordinateRegion(
                    center: nearest.coordinates,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
    }
}
    
    // Функция сортировки по расстоянию


// MARK: - Вспомогательное вычисляемое свойство для Terminal
extension Terminal {
    var distanceValue: Double {
        // Извлечь число из строки, например, "0.2 км" -> 0.2
        let numberString = distance.replacingOccurrences(of: " км", with: "").replacingOccurrences(of: ",", with: ".")
        return Double(numberString) ?? Double.greatestFiniteMagnitude
    }
}
