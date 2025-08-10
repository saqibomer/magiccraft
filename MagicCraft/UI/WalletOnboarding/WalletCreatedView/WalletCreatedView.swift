//
//  WalletCreatedView.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//

import SwiftUI

struct WalletCreatedView: View {
    let mnemonic: String
    @Binding var passcode: String
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Your wallet has been created!")
                .font(.headline)
            
            Text("Mnemonic:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(mnemonic)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .font(.footnote.monospaced())
            
            SecureField("Enter passcode to encrypt", text: $passcode)
                .textContentType(.password)
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            
            Button(action: onSave) {
                Label("Save Wallet", systemImage: "tray.and.arrow.down.fill")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

