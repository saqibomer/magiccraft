//
//  SendView.swift
//  MagicCraft
//
//  Created by TOxIC on 11/08/2025.
//

import SwiftUI
import Web3Core

struct SendView: View {
    @StateObject var viewModel: SendViewModel
    @State private var isShowingScanner = false
    @State private var scannerError: String? = nil
    
    // Add selected chain state
    @State private var selectedChainName: String
    
    
    init(viewModel: SendViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _selectedChainName = State(initialValue: viewModel.selectedChainName)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Chain picker
            Picker("Select Chain", selection: $selectedChainName) {
                ForEach(viewModel.chains.map { $0.name }, id: \.self) { chainName in
                    Text(chainName).tag(chainName)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal)
            .onChange(of: selectedChainName) { _, newChain in
                viewModel.selectedChainName = newChain
                updateTokenTypeForSelectedChain()
            }
            
            TextField("Recipient Address", text: $viewModel.recipientAddress)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .disabled(viewModel.isSending || viewModel.isEstimatingGas)
            
            TextField("Amount", text: $viewModel.amountString)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .keyboardType(.decimalPad)
                .disabled(viewModel.isSending || viewModel.isEstimatingGas)
            
            // Token picker with native and MCRT option
            Picker("Token", selection: $viewModel.tokenType) {
                Text("Native Coin").tag(TokenType.native)
                if let mcrtAddress = getMCRTContractAddress(for: selectedChainName) {
                    Text("MCRT (ERC20)").tag(TokenType.erc20(contractAddress: mcrtAddress))
                } else {
                    Text("MCRT (ERC20) - Not available").disabled(true)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .disabled(viewModel.isSending || viewModel.isEstimatingGas)
            
            Button("Scan QR Code") {
                scannerError = nil
                isShowingScanner = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSending || viewModel.isEstimatingGas)
            
            Button("Estimate Gas & Confirm") {
                Task {
                    await viewModel.estimateGas()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.recipientAddress.isEmpty || viewModel.amountString.isEmpty || viewModel.isSending || viewModel.isEstimatingGas)
            
            Spacer()
            
            if viewModel.isEstimatingGas {
                ProgressView("Estimating Gas...")
                    .padding()
            }
            
            if viewModel.showConfirmation {
                VStack(spacing: 10) {
                    Text("Estimated Gas Fee: \(viewModel.estimatedFeeEth) ETH")
                        .font(.headline)
                    
                    HStack {
                        Button("Cancel") {
                            viewModel.showConfirmation = false
                            viewModel.errorMessage = nil
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Send") {
                            Task {
                                await sendTransaction()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isSending)
                    }
                }
                .padding()
            }
            
            
            if viewModel.isSending {
                ProgressView("Sending Transaction...")
                    .padding()
            }
            
            if let error = viewModel.errorMessage ?? scannerError {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            if let tx = viewModel.txHash {
                VStack(spacing: 5) {
                    Text("Transaction Sent Successfully!")
                        .font(.headline)
                    Text(tx)
                        .font(.footnote)
                        .textSelection(.enabled)
                        .padding()
                }
            }
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
        .onAppear {
            updateTokenTypeForSelectedChain()
            Task {
                await viewModel.loadKeystore()
                await viewModel.updateWeb3ForSelectedChain()
            }
        }
    }
    
    private func getMCRTContractAddress(for chainName: String) -> EthereumAddress? {
        guard let chain = viewModel.chains.first(where: { $0.name == chainName }),
              !chain.mcrtContractAddress.isEmpty else {
            return nil
        }
        return EthereumAddress(chain.mcrtContractAddress)
    }
    
    private func updateTokenTypeForSelectedChain() {
        if let mcrtAddress = getMCRTContractAddress(for: selectedChainName) {
            viewModel.tokenType = .erc20(contractAddress: mcrtAddress)
        } else {
            viewModel.tokenType = .native
        }
        Task {
            await viewModel.updateWeb3ForSelectedChain()
        }
    }
    
    private func sendTransaction() async {
        await viewModel.sendTransaction()
    }
    
    
}
