//
//  TokenType.swift
//  MagicCraft
//
//  Created by TOxIC on 11/08/2025.
//
import Web3Core

enum TokenType: Hashable {
    case native
    case erc20(contractAddress: EthereumAddress)
}
