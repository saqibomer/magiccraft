//
//  SendTransactionView.swift
//  MagicCraft
//
//  Created by TOxIC on 11/08/2025.
//

import SwiftUI
import Web3Core
import web3swift

struct SendTransactionView: View {
    @StateObject private var vm: SendTransactionViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    init(web3: Web3,
         walletAddress: EthereumAddress,
//         keystoreManager: KeystoreManager,
         password: String,
         chainName: String?) {
        _vm = StateObject(wrappedValue: SendTransactionViewModel(
            web3: web3,
            walletAddress: walletAddress,
//            keystoreManager: keystoreManager,
            password: password
        ))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Recipient Address Field
            TextField("Recipient Address", text: $vm.recipient)
                .textInputAutocapitalization(.none)
                .disableAutocorrection(true)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .padding(.horizontal)
            
            // Amount Field
            TextField("Amount to send", text: $vm.amount)
                .keyboardType(.decimalPad)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .padding(.horizontal)
            
            // Token Type Picker
            Picker("Token Type", selection: $vm.tokenType) {
                Text("Native Coin").tag(TokenType.native)
                Text("MCRT Token").tag(TokenType.erc20(
                    contractAddress: EthereumAddress("0xde16ce60804a881e9f8c4ebb3824646edecd478d")!
                ))
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Error Message
            if let error = vm.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // Transaction Status
            if let txHash = vm.txHash {
                VStack {
                    Text("Transaction sent!")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    Text(txHash)
                        .font(.footnote)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    Button("Done") {
                        dismiss()
                    }
                    .padding(.top)
                }
                .padding()
            }
            
            Spacer()
            
            // Action Button
            Button {
                Task {
                    await vm.estimateGas()
                }
            } label: {
                if vm.isLoading {
                    ProgressView()
                } else {
                    Text(vm.txHash == nil ? "Review Transaction" : "Send Another")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(!vm.isInputValid || vm.isLoading)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        .padding(.vertical)
        .navigationTitle("Send Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Confirm Transaction",
                          isPresented: $vm.showConfirmation,
                          titleVisibility: .visible) {
            if let gas = vm.gasEstimate,
               let gasPrice = vm.gasPrice,
               let fee = vm.estimatedFee {
                
                Button("Confirm & Send") {
                    Task {
                        await vm.sendTransaction()
                    }
                }
                
                Button("Cancel", role: .cancel) {}
            }
        } message: {
            if let gas = vm.gasEstimate,
               let gasPrice = vm.gasPrice,
               let fee = vm.estimatedFee {
                
                VStack {
                    Text("Gas Limit: \(gas.description)")
                    Text("Gas Price: \(Utilities.formatToPrecision(gasPrice, formattingDecimals: 2)) Gwei")
                    Text("Estimated Fee: \(fee.formatted()) ETH")
                }
            }
        }
        .toolbar {
            if vm.txHash != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
