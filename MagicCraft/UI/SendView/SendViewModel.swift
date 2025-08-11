//
//  SendViewModel.swift
//  MagicCraft
//
//  Created by TOxIC on 11/08/2025.
//

import SwiftUI
import Combine

@MainActor
class SendViewModel: ObservableObject {
    @Published var recipientAddress: String = ""
    @Published var amount: String = ""
    
    // Add your transaction sending logic here
    func sendTransaction() {
        // Implement sending with recipientAddress and amount
        print("Send to \(recipientAddress) amount \(amount)")
    }
    
    func updateRecipient(with scannedCode: String) {
        // Basic validation or filtering could go here
        recipientAddress = scannedCode
    }
}
