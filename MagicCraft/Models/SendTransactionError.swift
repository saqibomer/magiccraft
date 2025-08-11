//
//  SendTransactionError.swift
//  MagicCraft
//
//  Created by TOxIC on 11/08/2025.
//

enum SendTransactionError: Error {
    case contractError
    case invalidInput
    case gasEstimateFailed
    case transactionFailed
}
