//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 29.12.2023.
//

import StoreKit

extension SKPaymentTransaction {
    @objc var productId: String {
        payment.productIdentifier
    }
}

extension SKPaymentTransaction {
    var logDescription: String {
        "Transaction \(transactionIdentifier ?? "") for product \(payment.productIdentifier), quantity: \(payment.quantity), status \(transactionState.debugName)"
    }
}
