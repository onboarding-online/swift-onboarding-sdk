//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 29.12.2023.
//

import Foundation

public enum OPSTransactionError: LocalizedError {
    case cancelled, notFound, other(message: String)
    
    public var errorDescription: String? {
        switch self {
        case .cancelled:
            return "cancelled"
        case .notFound:
            return "notFound"
        case .other(let message):
            return "Other: \(message)"
        }
    }
}
