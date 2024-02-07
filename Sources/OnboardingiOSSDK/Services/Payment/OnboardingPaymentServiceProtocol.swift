//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 28.12.2023.
//

import Foundation
import StoreKit

public protocol OnboardingPaymentServiceProtocol {
    var canMakePayments: Bool { get }
    
    func fetchProductsWith(ids: Set<String>) async throws -> [SKProduct]
    func restorePurchases() async throws
    
    /// Purchase SKProduct
    /// - Parameter product: SKProduct to purchase
    /// NOTE: Throw OnboardingPaywallError.cancelled if you don't want to show error alert when user cancel purchase.
    func purchaseProduct(_ product: SKProduct) async throws
    
    func hasActiveSubscription() async throws -> Bool
}
