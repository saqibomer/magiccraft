//
//  SendView.swift
//  MagicCraft
//
//  Created by TOxIC on 11/08/2025.
//

import SwiftUI

struct SendView: View {
    @StateObject var viewModel = SendViewModel()
    @State private var isShowingScanner = false
    @State private var scannerError: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Recipient Address", text: $viewModel.recipientAddress)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            TextField("Amount", text: $viewModel.amount)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .keyboardType(.decimalPad)
            
            Button("Scan QR Code") {
                scannerError = nil
                isShowingScanner = true
            }
            .buttonStyle(.borderedProminent)
            
            Button("Send") {
                viewModel.sendTransaction()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.recipientAddress.isEmpty || viewModel.amount.isEmpty)
            
            if let error = scannerError {
                Text("Scanner error: \(error)")
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
        .navigationTitle("Send")
        .sheet(isPresented: $isShowingScanner) {
            QRCodeScannerView { result in
                isShowingScanner = false
                switch result {
                case .success(let code):
                    viewModel.updateRecipient(with: code)
                case .failure(let error):
                    scannerError = error.localizedDescription
                }
            }
        }
    }
}
