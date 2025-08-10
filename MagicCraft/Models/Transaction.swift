//
//  Transaction.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//
import Foundation

struct Transaction: Identifiable {
    let id = UUID()
    let hash: String
    let from: String
    let to: String
    let value: Decimal
    let timeStamp: Date
    let explorerUrl: String
}
