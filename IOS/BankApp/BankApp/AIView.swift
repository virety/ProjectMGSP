//
//  AIView.swift
//  BankApp
//
//  Created by Вадим Семибратов on 02.06.2025.
//

import SwiftUI
import Speech
import AVFoundation
import OpenAISwift

// 1. Безопасное хранение ключа (в реальном проекте используйте Keychain)
struct Secrets {
    static let openAIKey = "key" // Замените на свой ключ
}


struct OpenAIChatMessage: Codable {
    let role: Role
    let content: String
}

struct OpenAIChatRequest: Codable {
    let model: String
    let messages: [OpenAIChatMessage]
}
enum Role: String, Codable {
    case system
    case user
    case assistant
}
struct OpenAIChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
    }
    
    let choices: [Choice]
}

struct AIView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [ChatMessage] = []
    @State private var newMessage: String = ""
    @State private var isRecording = false
    @State private var isThinking = false
    @State private var openAI: OpenAISwift
    
    // Аудио компоненты
    private let audioEngine = AVAudioEngine()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))!
    
    init() {
        let config = OpenAISwift.Config(
            baseURL: "https://api.openai.com/v1/",
            endpointPrivider: OpenAIEndpointProvider(source: .openAI),
            session: .shared,
            authorizeRequest: { request in
                request.setValue("Bearer \(Secrets.openAIKey)", forHTTPHeaderField: "Authorization")
            }
        )
        _openAI = State(initialValue: OpenAISwift(config: config))
    }
    
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
                // Шапка
                headerView()
                
                // Область чата
                chatView()
                
                // Панель ввода
                inputView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            requestSpeechAuthorization()
            showGreeting()
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    // MARK: - Компоненты интерфейса
    
    private func headerView() -> some View {
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
            
            HStack(spacing: 4) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18))
                Text("Ассистент")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(8)
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    private func chatView() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }
                    
                    if isThinking {
                        ThinkingIndicator()
                            .id("thinking")
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .onChange(of: messages) { _ in
                    withAnimation {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
        }
    }
    
    private func inputView() -> some View {
        HStack(spacing: 12) {
            // Кнопка голосового ввода
            Button(action: toggleVoiceInput) {
                Image(systemName: isRecording ? "waveform" : "mic.fill")
                    .foregroundColor(isRecording ? .red : .white)
                    .padding(10)
                    .background(isRecording ? Color.white.opacity(0.3) : Color.blue.opacity(0.7))
                    .clipShape(Circle())
            }
            
            TextField("Введите сообщение...", text: $newMessage)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.green)
                    .clipShape(Circle())
            }
            .disabled(newMessage.isEmpty || isThinking)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.2))
    }
    
    // MARK: - Логика чата
    
    private func showGreeting() {
        let greeting: String
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 6..<12: greeting = "Доброе утро! ☀️"
        case 12..<18: greeting = "Добрый день! 🌤"
        case 18..<23: greeting = "Добрый вечер! 🌙"
        default: greeting = "Доброй ночи! 🌚"
        }
        
        let welcomeMessage = ChatMessage(
            text: "\(greeting) Я ваш банковский ассистент. Чем могу помочь?",
            isUser: false,
            timestamp: Date()
        )
        
        messages.append(welcomeMessage)
    }
    
    private func sendMessage() {
        guard !newMessage.isEmpty else { return }
        
        let userMessage = ChatMessage(
            text: newMessage,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        newMessage = ""
        
        sendToAI(message: userMessage.text)
    }
    
    private func sendToAI(message: String) {
        isThinking = true

        let context = """
        Ты - AI-ассистент банка. Отвечай кратко и профессионально.
        Помогай с вопросами по: счетам, переводам, картам, кредитам.
        Текущая дата: \(Date().formatted(date: .long, time: .omitted))
        """

        let messages: [OpenAIChatMessage] = [
            OpenAIChatMessage(role: .system, content: context),
            OpenAIChatMessage(role: .user, content: message)
        ]

        let request = OpenAIChatRequest(
            model: "gpt-3.5-turbo",
            messages: messages
        )

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            showError("Неверный URL запроса")
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(Secrets.openAIKey)", forHTTPHeaderField: "Authorization")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            showError("Ошибка формирования запроса: \(error.localizedDescription)")
            return
        }

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                isThinking = false
            }

            if let error = error {
                showError("Ошибка сети: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                showError("Неверный ответ сервера")
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                if let data = data, let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                    showError("Ошибка API: \(errorResponse.error.message)")
                } else {
                    showError("Ошибка сервера: \(httpResponse.statusCode)")
                }
                return
            }

            guard let data = data else {
                showError("Пустой ответ от сервера")
                return
            }

            do {
                let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
                if let reply = decoded.choices.first?.message.content {
                    DispatchQueue.main.async {
                        let aiMessage = ChatMessage(
                            text: reply,
                            isUser: false,
                            timestamp: Date()
                        )
                        self.messages.append(aiMessage)
                    }
                }
            } catch {
                let responseString = String(data: data, encoding: .utf8) ?? "Неизвестный формат"
                print("Ошибка декодирования. Ответ сервера:", responseString)
                showError("Ошибка обработки ответа. Подробности в консоли")
            }
        }.resume()
    }

    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.messages.append(ChatMessage(
                text: message,
                isUser: false,
                timestamp: Date()
            ))
            isThinking = false
        }
    }

    // Добавьте эту структуру для обработки ошибок OpenAI
    struct OpenAIErrorResponse: Codable {
        struct Error: Codable {
            let message: String
            let type: String
        }
        let error: Error
    }
    // MARK: - Голосовой ввод
    
    private func toggleVoiceInput() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            requestSpeechAuthorization()
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            
            let inputNode = audioEngine.inputNode
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            guard let recognitionRequest = recognitionRequest else { return }
            recognitionRequest.shouldReportPartialResults = true
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                if let result = result {
                    newMessage = result.bestTranscription.formattedString
                }
                
                if error != nil {
                    stopRecording()
                }
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Ошибка голосового ввода: \(error.localizedDescription)")
            messages.append(ChatMessage(
                text: "Не удалось начать запись",
                isUser: false,
                timestamp: Date()
            ))
        }
    }
    
    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isRecording = false
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Ошибка остановки аудиосессии: \(error)")
        }
    }
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                if status != .authorized {
                    messages.append(ChatMessage(
                        text: "Требуется разрешение на использование микрофона",
                        isUser: false,
                        timestamp: Date()
                    ))
                }
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard !messages.isEmpty else { return }
        let lastId = messages[messages.count - 1].id
        proxy.scrollTo(lastId, anchor: .bottom)
    }
}

// MARK: - Вспомогательные структуры

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
    
    func toChatMessage() -> OpenAIChatMessage {
        OpenAIChatMessage(role: isUser ? .user : .assistant, content: text)
    }
}
struct ThinkingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            Text("Ассистент думает...")
                .foregroundColor(.white.opacity(0.7))
            
            HStack(spacing: 5) {
                ForEach(0..<3) { i in
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundColor(.green)
                        .opacity(isAnimating ? 0.3 : 1)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(i) * 0.2),
                            value: isAnimating
                        )
                }
            }
            .onAppear { isAnimating = true }
            
            Spacer()
        }
        .padding(12)
        .background(Color.green.opacity(0.2))
        .cornerRadius(12, corners: [.topRight, .bottomLeft, .bottomRight])
        .padding(.horizontal)
    }
}

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.text)
                    .padding(12)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "5E60BB"), Color(hex: "B2F7FF")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12, corners: [.topLeft, .bottomLeft, .bottomRight])
            } else {
                Text(message.text)
                    .padding(12)
                    .background(
                        LinearGradient(
                            colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12, corners: [.topRight, .bottomLeft, .bottomRight])
                Spacer()
            }
        }
    }
}

// MARK: - Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
