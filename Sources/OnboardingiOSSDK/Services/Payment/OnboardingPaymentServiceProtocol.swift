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
    func cashedProductsWith(ids: Set<String>) -> [SKProduct]? 

    func restorePurchases() async throws
    
    /// Purchase SKProduct
    /// - Parameter product: SKProduct to purchase
    /// NOTE: Throw OnboardingPaywallError.cancelled if you don't want to show error alert when user cancel purchase.
    func purchaseProduct(_ product: SKProduct) async throws
    
    func activeSubscriptionReceipt() async throws -> OnboardingPaymentReceipt?
    func lastPurchaseReceipts() async throws -> OnboardingPaymentReceipt?
    func hasActiveSubscription() async throws -> Bool
}

public struct OnboardingPaymentReceipt {
    public let productId: String
    public let quantity: String
    public let transactionId: String
    public let originalTransactionId: String
    public let purchaseDate: Date
    public let originalPurchaseDate: Date?
    public let isTrialPeriod: String
    public let expiresDate: Date?
    public let isInIntroOfferPeriod: String?
    public let webOrderLineItemId: String?
    public let cancellationDate: Date?
    public var isSubscription: Bool { expiresDate != nil && cancellationDate == nil }
    
    public init(productId: String,
                quantity: String,
                transactionId: String,
                originalTransactionId: String,
                purchaseDate: Date, 
                originalPurchaseDate: Date? = nil,
                isTrialPeriod: String,
                expiresDate: Date? = nil,
                isInIntroOfferPeriod: String? = nil,
                webOrderLineItemId: String? = nil,
                cancellationDate: Date? = nil) {
        self.productId = productId
        self.quantity = quantity
        self.transactionId = transactionId
        self.originalTransactionId = originalTransactionId
        self.purchaseDate = purchaseDate
        self.originalPurchaseDate = originalPurchaseDate
        self.isTrialPeriod = isTrialPeriod
        self.expiresDate = expiresDate
        self.isInIntroOfferPeriod = isInIntroOfferPeriod
        self.webOrderLineItemId = webOrderLineItemId
        self.cancellationDate = cancellationDate
    }
}
