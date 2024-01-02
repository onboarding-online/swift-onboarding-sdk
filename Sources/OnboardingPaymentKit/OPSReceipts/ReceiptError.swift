//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 28.12.2023.
//

import Foundation

/// Error when managing receipt
public enum ReceiptError: Error {
    /// No receipt data
    case noReceiptData // .4
    /// No data received
    case noRemoteData // .5
    /// Error when encoding HTTP body into JSON
    case requestBodyEncodeError(error: Swift.Error)
    /// Error when proceeding request
    case networkError(error: Swift.Error)
    /// Error when decoding response
    case jsonDecodeError(string: String?) // .2
    /// Receive invalid - bad status returned
    case receiptInvalid(status: ReceiptStatus) // .3
    
    public var description: String {
        switch self {
        case .noReceiptData:
            return "There's no receipt data."
        case .noRemoteData:
            return "Couldn't load data. Check your internet connection"
        case .requestBodyEncodeError(let error):
            return "Failed to encode request body: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network failed to load receipt with error \(error.localizedDescription). Check your internet connection"
        case .jsonDecodeError(let string):
            return "Failed to decode receipt: \(string ?? "")"
        case .receiptInvalid(let status):
            return "Invalid receipt with code: \(status.rawValue)"
        }
    }
}

extension ReceiptError: Equatable {
    public static func == (lhs: ReceiptError, rhs: ReceiptError) -> Bool {
        switch (lhs, rhs) {
        case (.noReceiptData, .noReceiptData):
            return true
        case (.noRemoteData, .noRemoteData):
            return true
        case (.requestBodyEncodeError, .requestBodyEncodeError):
            return true
        case (.networkError, .networkError):
            return true
        case (.jsonDecodeError(let lhsEncodedError), .jsonDecodeError(let rhsEncodedError)):
            return lhsEncodedError == rhsEncodedError
        case (.receiptInvalid(let lhsEncodedError), .receiptInvalid(let rhsEncodedError)):
            return lhsEncodedError == rhsEncodedError
        default:
            return false 
        }
    }
}
