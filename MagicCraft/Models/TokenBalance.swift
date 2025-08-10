//
//  TokenBalance.swift
//  MagicCraft
//
//  Created by TOxIC on 10/08/2025.
//
import Foundation

struct TokenBalance: Identifiable {
    let id = UUID()
    let chainName: String
    let symbol: String
    let balance: Decimal
}
