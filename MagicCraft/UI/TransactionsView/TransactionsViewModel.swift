//
//  TransactionsViewModel.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//

import Foundation
import Combine
import BigInt

@MainActor
class TransactionsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    private let walletAddress: String
    private let apiKey: String
    private let action: String  // "txlist", "tokentx", or "txlistinternal"
    private let limit: Int
    
    let chainConfig: ChainAPIConfig
    
    init(walletAddress: String, apiKey: String, chainConfig: ChainAPIConfig, action: String = "txlist", limit: Int = 5) {
        self.walletAddress = walletAddress
        self.apiKey = apiKey
        self.chainConfig = chainConfig
        self.action = action
        self.limit = limit
    }
    
    func fetchTransactions() async {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string:
            "\(chainConfig.baseURL)?module=account&action=\(action)&address=\(walletAddress)&startblock=0&endblock=99999999&sort=desc&apikey=\(apiKey)"
        ) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let status = json["status"] as? String, status == "1",
                let result = json["result"] as? [[String: Any]]
            else {
                if let message = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                   let errorMsg = message["message"] as? String {
                    errorMessage = errorMsg
                } else {
                    errorMessage = "Unknown API error"
                }
                isLoading = false
                return
            }
            
            let latestTxs = result.prefix(limit).compactMap { tx -> Transaction? in
                guard
                    let hash = tx["hash"] as? String,
                    let from = tx["from"] as? String,
                    let to = tx["to"] as? String,
                    let valueStr = tx["value"] as? String,
                    let timeStampStr = tx["timeStamp"] as? String,
                    let timeStampInt = Double(timeStampStr),
                    let valueBigUInt = BigUInt(valueStr)
                else { return nil }
                
                let date = Date(timeIntervalSince1970: timeStampInt)
                let valueDecimal = Self.formatBalance(valueBigUInt)
                
                return Transaction(
                    hash: hash,
                    from: from,
                    to: to,
                    value: valueDecimal,
                    timeStamp: date,
                    explorerUrl: "\(chainConfig.explorerPrefix)\(hash)"
                )
            }
            
            transactions = Array(latestTxs)
            isLoading = false
            
        } catch {
            errorMessage = "Network error: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    static func formatBalance(_ balance: BigUInt, decimals: Int = 18) -> Decimal {
        let divisor = BigUInt(10).power(decimals)
        let balanceDecimal = Decimal(string: balance.description) ?? 0
        let divisorDecimal = Decimal(string: divisor.description) ?? 1
        return balanceDecimal / divisorDecimal
    }
}
