//
//  ReceiveView.swift
//  MagicCraft
//
//  Created by TOxIC on 11/08/2025.
//

import SwiftUI

struct ReceiveView: View {
    @StateObject var viewModel: ReceiveViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Receive")
                .font(.largeTitle)
                .bold()
            
            if let qrCodeImage = viewModel.qrCodeImage {
                Image(uiImage: qrCodeImage)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 250, height: 250)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 5)
            } else {
                Text("Unable to generate QR code")
                    .foregroundColor(.red)
            }
            
            Text(viewModel.walletAddress)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 40) {
                Button(action: {
                    UIPasteboard.general.string = viewModel.walletAddress
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {
                    let activityVC = UIActivityViewController(activityItems: [viewModel.walletAddress], applicationActivities: nil)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = windowScene.windows.first?.rootViewController {
                        rootVC.present(activityVC, animated: true)
                    }
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
    }
}
