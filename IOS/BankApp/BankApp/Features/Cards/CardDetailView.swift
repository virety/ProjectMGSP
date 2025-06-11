//
//  CardView.swift
//  BankApp
//
//  Created by Вадим Семибратов on 02.06.2025.
//

import CoreData
import SwiftUI
import PhotosUI

struct CardDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let card: BankCard
    @Environment(\.dismiss) private var dismiss
    
    @State private var cvvCode: String = "•••"
    @State private var isCardActive: Bool = true
    @State private var showConfirmCloseAlert = false
    @State private var showRenameCardAlert = false
    @State private var newCardName: String = ""
    @State private var showDesignSelector = false
    @State private var cardImage: UIImage?
    
    // Для управления таймером скрытия CVV
    @State private var cvvTimerTask: DispatchWorkItem?
    
    init(card: BankCard) {
        self.card = card
    }
    
    private func generateCVV() -> String {
        return String(format: "%03d", Int.random(in: 0..<1000))
    }
    
    private func saveCVVToDatabase() {
        let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "cardNumber == %@", card.number.replacingOccurrences(of: "**** ", with: ""))
        
        if let users = try? viewContext.fetch(fetchRequest), let user = users.first {
            let newCVV = generateCVV()
            user.cardCVV = newCVV
            do {
                try viewContext.save()
                cvvCode = newCVV
                startCVVHideTimer()
            } catch {
                print("Ошибка при сохранении CVV: \(error)")
            }
        }
    }
    
    private func loadCardData() {
        let fetchRequest: NSFetchRequest<BankApp.CDUser> = BankApp.CDUser.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "cardNumber == %@", card.number.replacingOccurrences(of: "**** ", with: ""))
        if let users = try? viewContext.fetch(fetchRequest), let user = users.first {
            cvvCode = user.cardCVV ?? "•••"
            isCardActive = user.isActive
            newCardName = user.cardName ?? ""
            
            if let imageData = user.cardImageData {
                cardImage = UIImage(data: imageData)
            } else {
                cardImage = nil
            }
        }
    }
    
    private func closeCard() {
        let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "cardNumber == %@", card.number.replacingOccurrences(of: "**** ", with: ""))
        if let users = try? viewContext.fetch(fetchRequest), let user = users.first {
            user.isActive = false
            do {
                try viewContext.save()
                isCardActive = false
            } catch {
                print("Ошибка при закрытии карты: \(error)")
            }
        }
    }
    
    private func unlockCard() {
        let fetchRequest: NSFetchRequest<BankApp.CDUser> = BankApp.CDUser.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "cardNumber == %@", card.number.replacingOccurrences(of: "**** ", with: ""))
        
        if let users = try? viewContext.fetch(fetchRequest), let user = users.first {
            user.isActive = true
            do {
                try viewContext.save()
                isCardActive = true
            } catch {
                print("Ошибка при разблокировке карты: \(error)")
            }
        }
    }
    
    private func renameCard() {
        let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "cardNumber == %@", card.number.replacingOccurrences(of: "**** ", with: ""))
        if let users = try? viewContext.fetch(fetchRequest), let user = users.first {
            user.cardName = newCardName
            do {
                try viewContext.save()
            } catch {
                print("Ошибка при переименовании карты: \(error)")
            }
        }
    }
    
    // Показываем CVV и запускаем таймер скрытия через 60 секунд
    private func showCVV() {
        let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "cardNumber == %@", card.number.replacingOccurrences(of: "**** ", with: ""))
        
        if let users = try? viewContext.fetch(fetchRequest), let user = users.first {
            let newCVV = user.cardCVV ?? generateCVV()
            cvvCode = newCVV
            startCVVHideTimer()
        }
    }
    
    // Запуск таймера для скрытия CVV
    private func startCVVHideTimer() {
        cvvTimerTask?.cancel()
        let task = DispatchWorkItem {
            withAnimation {
                cvvCode = "•••"
            }
        }
        cvvTimerTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 60, execute: task)
    }
    
    // Скрываем CVV и отменяем таймер
    private func resetCVV() {
        cvvTimerTask?.cancel()
        withAnimation {
            cvvCode = "•••"
        }
    }
    
    private func headerView() -> some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .ignoresSafeArea(edges: .top)
                .frame(height: 56)

            HStack(spacing: 6) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 18))
                Text("Карта")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            HStack {
                Button(action: { dismiss() }) {
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
    
    var body: some View {
        ZStack(alignment: .top) {
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
            
            VStack(spacing: 20) {
                headerView()
                
                ScrollView {
                    VStack(spacing: 20) {
                        ZStack {
                            Group {
                                if let uiImage = cardImage {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    LinearGradient(
                                        colors: [card.gradientStart, card.gradientEnd],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                }
                            }
                            .frame(height: 200)
                            .clipped()
                            
                            Color.black.opacity(0.25)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text(newCardName.isEmpty ? card.info : newCardName)
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.9))
                                Text(card.balance)
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.white)
                                Spacer()
                                HStack {
                                    Text(card.number)
                                    Spacer()
                                    Text(card.expiry)
                                }
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            }
                            .padding()
                        }
                        .frame(height: 200)
                        .cornerRadius(20)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        .onTapGesture {
                            showDesignSelector = true
                        }
                        
                        // CVV блок с кнопками показа и скрытия
                        // CVV блок с кнопками показа и скрытия
                        HStack {
                            if cvvCode == "•••" {
                                Button(action: {
                                    showCVV()
                                }) {
                                    Text("Показать CVV")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            } else {
                                HStack(spacing: 8) {
                                    Text(cvvCode)
                                        .font(.title3.monospacedDigit())
                                        .bold()
                                        .foregroundColor(.primary)
                                    
                                    Button(action: {
                                        resetCVV()
                                    }) {
                                        Image(systemName: "eye.slash.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                            }
                        }

                        .padding(.horizontal)
                        
                        if isCardActive {
                            Button(role: .destructive) {
                                showConfirmCloseAlert = true
                            } label: {
                                Text("Закрыть карту")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .alert("Вы уверены, что хотите закрыть эту карту?", isPresented: $showConfirmCloseAlert) {
                                Button("Отмена", role: .cancel) { }
                                Button("Закрыть", role: .destructive) {
                                    closeCard()
                                }
                            }

                            Button {
                                showRenameCardAlert = true
                            } label: {
                                Text("Переименовать карту")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .alert("Переименовать карту", isPresented: $showRenameCardAlert, actions: {
                                TextField("Новое имя карты", text: $newCardName)
                                Button("Отмена", role: .cancel) { }
                                Button("Сохранить") {
                                    renameCard()
                                }
                            })

                        } else {
                            Button {
                                unlockCard()
                            } label: {
                                Text("Разблокировать карту")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)

                            Text("Эта карта закрыта")
                                .foregroundColor(.red)
                                .padding()
                        }

                        Spacer()
                    }
                }
                
            }
        }
        .onAppear {
            loadCardData()
        }
        .onDisappear {
            resetCVV() // Скрываем CVV при выходе с экрана
        }
        .sheet(isPresented: $showDesignSelector, onDismiss: {
            loadCardData()
        }) {
            CardDesignSelectorView(card: card)
        }
        .toolbar(.hidden)
        .navigationBarBackButtonHidden(true)
    }
}

struct CardDesignSelectorView: View {
    let card: BankCard
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext

    @State private var selectedImage: UIImage?
    @State private var isShowingPhotoPicker = false

    private func saveImage(_ image: UIImage) {
        let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "cardNumber == %@", card.number.replacingOccurrences(of: "**** ", with: ""))
        
        if let users = try? viewContext.fetch(fetchRequest), let user = users.first {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                user.cardImageData = imageData
            }
            do {
                try viewContext.save()
                presentationMode.wrappedValue.dismiss()
            } catch {
                print("Ошибка сохранения изображения: \(error)")
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                } else {
                    Text("Выберите изображение для дизайна карты")
                        .foregroundColor(.secondary)
                        .padding()
                }

                Button("Выбрать фото из галереи") {
                    isShowingPhotoPicker = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)

                Spacer()
            }
            .padding()
            .navigationTitle("Выберите дизайн карты")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        if let selectedImage {
                            saveImage(selectedImage)
                        }
                    }
                    .disabled(selectedImage == nil)
                }
            }
            .sheet(isPresented: $isShowingPhotoPicker) {
                PhotoPicker(selectedImage: $selectedImage)
            }
        }
        .navigationViewStyle(.stack)
        .toolbar(.hidden) // Скрываем системный тулбар
        .navigationBarHidden(true) // Дополнительное скрытие
    
    }

    
    
}

// Обёртка для PHPickerViewController, чтобы выбрать фото из галереи
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else { return }
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}
