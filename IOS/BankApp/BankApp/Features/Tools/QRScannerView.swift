//
//  QRScannerView.swift
//  BankApp
//
//  Created by Вадим Семибратов on 04.06.2025.
//

import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @StateObject private var scanner = QRScannerViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showOverlayText = true

    var body: some View {
        ZStack {
            // Камера
            QRScannerPreview(session: scanner.session)
                .ignoresSafeArea()

            // Затемнённый фон + сканер рамка
            Rectangle()
                .fill(Color.black.opacity(0.4))
                .ignoresSafeArea()
            
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green, lineWidth: 3)
                .frame(width: 250, height: 250)
                .shadow(radius: 10)
            
            // Подсказка внизу
            VStack {
                Spacer()
                if showOverlayText {
                    Text("Наведите камеру на QR-код")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .transition(.opacity)
                        .padding(.bottom, 60)
                }
            }
            
            // **Ставим headerView в самый верх ZStack, чтобы он был поверх камеры**
            VStack {
                headerView()
                Spacer()
            }
        }
        .onAppear {
            scanner.start()
            withAnimation(.easeInOut(duration: 1.5).delay(1.0)) {
                showOverlayText = true
            }
        }
        .onDisappear {
            scanner.stop()
        }
    }
    private func headerView() -> some View {
        ZStack {
            // Фон toolbar
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .ignoresSafeArea(edges: .top)
                .frame(height: 56)
            
            // Содержимое toolbar
            HStack {
                // Кнопка "Назад"
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                // Заголовок
                HStack(spacing: 6) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 18))
                    Text("Сканер QR")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                
                Spacer()
                
                // Невидимая кнопка для балансировки
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .opacity(0)
                        .padding(8)
                }
                .disabled(true)
            }
            .padding(.horizontal)
        }
        .frame(height: 56)
    }
    
}
struct QRScannerPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
class QRScannerViewModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var scannedCode: String?
    
    let session = AVCaptureSession()
    
    override init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else { return }
        
        session.addInput(videoInput)
        
        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }
    }
    
    func start() {
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    
    func stop() {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }


    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           metadataObject.type == .qr,
           let stringValue = metadataObject.stringValue {
            scannedCode = stringValue
            stop()
        }
    }
}
struct PaymentResultView: View {
    let qrData: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Платёж по QR")
                .font(.title)
            
            Text("Данные QR:")
                .font(.headline)
            
            Text(qrData)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()

            Button("Подтвердить оплату") {
                // Реализация оплаты
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .padding()
        .navigationTitle("Оплата")
        .navigationBarTitleDisplayMode(.inline)
    }
}
