//
//  ReceiveViewModel.swift
//  MagicCraft
//
//  Created by TOxIC on 11/08/2025.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import Combine

@MainActor
class ReceiveViewModel: ObservableObject {
    @Published var walletAddress: String
    
    @Published var qrCodeImage: UIImage? = nil
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    init(walletAddress: String) {
        self.walletAddress = walletAddress
        generateQRCode()
    }
    
    func generateQRCode() {
        let data = Data(walletAddress.utf8)
        filter.setValue(data, forKey: "inputMessage")
        print(walletAddress)
        
        if let outputImage = filter.outputImage {
            let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
            if let cgimg = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrCodeImage = UIImage(cgImage: cgimg)
            } else {
                qrCodeImage = nil
            }
        } else {
            qrCodeImage = nil
        }
    }
    
    func updateAddress(_ newAddress: String) {
        walletAddress = newAddress
        generateQRCode()
    }
}
