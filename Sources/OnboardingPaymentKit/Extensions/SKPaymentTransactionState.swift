//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 29.12.2023.
//

import StoreKit

extension SKPaymentTransactionState {
    var debugName: String {
        switch self {
        case .purchasing:
            return "Purchasing"
        case .purchased:
            return "Purchased"
        case .failed:
            return "Failed"
        case .restored:
            return "Restored"
        case .deferred:
            return "Deffered"
        @unknown default:
            return "Unknown transaction state"
        }
    }
}
