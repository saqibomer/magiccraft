//
//  WalletSetupStepView.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//
import SwiftUI

struct WalletSetupStepView: View {
    @Binding var isImporting: Bool
    @Binding var importMnemonic: String
    let onCreate: () -> Void
    let onImport: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: onCreate) {
                Label("Create New Wallet", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            
            Button(action: { isImporting.toggle() }) {
                Label("Import Wallet", systemImage: "square.and.arrow.down.fill")
            }
            .buttonStyle(.bordered)
            
            if isImporting {
                VStack(spacing: 8) {
                    TextField("Enter 12-word mnemonic", text: $importMnemonic)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.top, 4)
                    
                    Button(action: onImport) {
                        Label("Import", systemImage: "arrow.down.circle")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}


