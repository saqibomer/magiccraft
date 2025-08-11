//
//  QRCodeScannerView.swift
//  MagicCraft
//
//  Created by TOxIC on 11/08/2025.
//

import SwiftUI
import AVFoundation

struct QRCodeScannerView: UIViewControllerRepresentable {
    typealias CompletionHandler = (Result<String, ScanError>) -> Void
    
    enum ScanError: Error, LocalizedError {
        case badInput, badOutput, initError
        
        var errorDescription: String? {
            switch self {
            case .badInput: return "Cannot access camera."
            case .badOutput: return "Cannot process camera output."
            case .initError: return "Failed to initialize scanner."
            }
        }
    }
    
    var completion: CompletionHandler
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        controller.onFail = { error in
            completion(.failure(error))
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRCodeScannerView
        
        init(parent: QRCodeScannerView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput metadataObjects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            
            if let metadataObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
               let stringValue = metadataObj.stringValue {
                parent.completion(.success(stringValue))
            }
        }
    }
    
    class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
        var captureSession: AVCaptureSession!
        var previewLayer: AVCaptureVideoPreviewLayer!
        var delegate: AVCaptureMetadataOutputObjectsDelegate?
        var onFail: ((ScanError) -> Void)?
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            view.backgroundColor = UIColor.black
            captureSession = AVCaptureSession()
            
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                onFail?(.badInput)
                return
            }
            
            guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
                onFail?(.badInput)
                return
            }
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                onFail?(.badInput)
                return
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                onFail?(.badOutput)
                return
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }

        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
        }
        
        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            return .portrait
        }
    }
}
