//
//  File.swift
//
//
//  Created by Oleg Kuplin on 28.12.2023.
//

import Foundation
import StoreKit

public struct OPSPaymentTransaction: Hashable {
    
    let product: SKProduct
    let discount: AnyObject?
    let quantity: Int
    let simulatesAskToBuyInSandbox: Bool
    /// According to Apple documentation from:
    /// https://developer.apple.com/documentation/storekit/in-app_purchase/choosing_a_receipt_validation_technique
    /// Consumable in-app purchases remain in the receipt until you call finishTransaction(_:). Maintain and manage records of consumables on a server if needed. Non-consumables, auto-renewing subscription items, and non-renewing subscription items remain in the receipt indefinitely.
    // MARK: - It is important to provide content before completing transaction when purchase consumable item
    let autoComplete: Bool
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(product)
        hasher.combine(quantity)
        hasher.combine(autoComplete)
        hasher.combine(simulatesAskToBuyInSandbox)
    }
    
    public static func == (lhs: OPSPaymentTransaction, rhs: OPSPaymentTransaction) -> Bool {
        return lhs.product.productIdentifier == rhs.product.productIdentifier
    }
    
    var logDescription: String {
        "OPSPaymentTransaction for product \(product.productIdentifier), quantity: \(quantity), simluateAskToBuy: \(simulatesAskToBuyInSandbox), autoComplete: \(autoComplete)"
    }
}
