//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 28.12.2023.
//

import Foundation
import StoreKit
import OnboardingiOSSDK

public final class OnboardingPaymentService {

    private let productsManager = OPSProductsManager(fetcher: OPSSKProductsFetcher())
    private let transactionsManager: OPSTransactionsManagerProtocol = OPSTransactionsManager(paymentQueue: SKPaymentQueue.default())
    private let receiptsManager = OPSReceiptsManager()
    
    private var simulatesAskToBuyInSandbox: Bool
    private var autoComplete: Bool
    private var sharedSecret: String

    public init(simulatesAskToBuyInSandbox: Bool = false,
                autoComplete: Bool = true,
                sharedSecret: String) {
        self.simulatesAskToBuyInSandbox = simulatesAskToBuyInSandbox
        self.autoComplete = autoComplete
        self.sharedSecret = sharedSecret
    }
        
}

// MARK: - OnboardingPaymentServiceProtocol
extension OnboardingPaymentService: OnboardingPaymentServiceProtocol {
    
    public var canMakePayments: Bool {
        SKPaymentQueue.canMakePayments()
    }
    
    public func fetchProductsWith(ids: Set<String>) async throws -> [SKProduct] {
        let response: OPSProductsResponse = try await fetchProductsWith(ids: ids)
        return response.products
    }
    
    public func cashedProductsWith(ids: Set<String>) -> [SKProduct]? {
        let response: OPSProductsResponse? = cashedProductsWith(ids: ids)
        return response?.products
    }
    
    public func restorePurchases() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            restorePurchases() { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func purchaseProduct(_ product: SKProduct) async throws {
        let transaction = OPSPaymentTransaction(product: product,
                                                discount: nil,
                                                quantity: 1,
                                                simulatesAskToBuyInSandbox: simulatesAskToBuyInSandbox,
                                                autoComplete: autoComplete)
        do {
            _ = try await perform(transaction: transaction)
        } catch OPSTransactionError.cancelled {
            throw OnboardingPaywallError.cancelled
        } catch {
            throw error
        }
    }
    
    public func activeSubscriptionReceipt() async throws -> OnboardingPaymentReceipt? {
        let validatedReceipt = try await validateReceipt(sharedSecret: sharedSecret)
        if let appStoreReceipt = validatedReceipt.activeSubscriptionReceipt() {
            let onboardingReceipt = transformAppStoreReceiptToOnboardingReceipt(appStoreReceipt)
            return onboardingReceipt
        }
        return nil
    }
    
    public func lastPurchaseReceipts() async throws -> OnboardingPaymentReceipt? {
        let validatedReceipt = try await validateReceipt(sharedSecret: sharedSecret)
        if let appStoreReceipt = validatedReceipt.lastPurchaseReceipts() {
            let onboardingReceipt = transformAppStoreReceiptToOnboardingReceipt(appStoreReceipt)
            return onboardingReceipt
        }
        return nil
    }
    
    public func hasActiveSubscription() async throws -> Bool {
        let receipt = try await validateReceipt(sharedSecret: sharedSecret)
        let subStatuses = receipt.subscriptionsStatuses()
        return subStatuses.first(where: { $0.isActive }) != nil
    }
}

// MARK: - Private methods
private extension OnboardingPaymentService {
    
    func fetchProductsWith(ids: SKProductIDs) async throws -> OPSProductsResponse  {
        try await productsManager.fetchProductsWith(ids: ids)
    }
    
    func cashedProductsWith(ids: SKProductIDs) -> OPSProductsResponse?  {
        return productsManager.cachedProducts(ids: ids)
    }
    
    func perform(transaction: OPSPaymentTransaction, completion: @escaping OPSTransactionResultCallback) {
        transactionsManager.performTransaction(transaction: transaction, completion: completion)
    }
    
    func perform(transaction: OPSPaymentTransaction) async throws -> OPSTransactionStatus {
        return try await withCheckedThrowingContinuation { continuation in
            perform(transaction: transaction) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func restorePurchases(completion: @escaping OPSRestoreResultCallback) {
        transactionsManager.restorePurchases(completion: completion)
    }
    
    func refreshReceipt(forceReload: Bool) async throws {
        try await receiptsManager.refreshReceipt(forceReload: forceReload)
    }
    
    @available(*, renamed: "validateReceipt(sharedSecret:)")
    func validateReceipt(sharedSecret: String, completion: @escaping OPSReceiptValidationResultCallback) {
        receiptsManager.validateReceipt(sharedSecret: sharedSecret, completion: completion)
    }
    
    func validateReceipt(sharedSecret: String) async throws -> AppStoreValidatedReceipt {
        return try await withCheckedThrowingContinuation { continuation in
            validateReceipt(sharedSecret: sharedSecret) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func canCompleteTransactionWithId(_ transactionId: String) -> Bool {
        transactionsManager.canCompleteTransactionWithId(transactionId)
    }
    
    func completeTransactionWithId(_ transactionId: String) -> Result<Void, OPSTransactionError> {
        return transactionsManager.completeTransactionWithId(transactionId)
    }
    
    func setSKTransactionsDelegate(_ delegate: OPSTransactionsManagerDelegate) {
        transactionsManager.delegate = delegate
    }
}

// MARK: - Private methods
private extension OnboardingPaymentService {
    func transformAppStoreReceiptToOnboardingReceipt(_ appStoreReceipt: AppStoreReceiptInApp) -> OnboardingPaymentReceipt {
        OnboardingPaymentReceipt(productId: appStoreReceipt.productId,
                                 quantity: appStoreReceipt.quantity,
                                 transactionId: appStoreReceipt.transactionId,
                                 originalTransactionId: appStoreReceipt.originalTransactionId,
                                 purchaseDate: appStoreReceipt.purchaseDate,
                                 originalPurchaseDate: appStoreReceipt.originalPurchaseDate,
                                 isTrialPeriod: appStoreReceipt.isTrialPeriod,
                                 expiresDate: appStoreReceipt.expiresDate,
                                 isInIntroOfferPeriod: appStoreReceipt.isInIntroOfferPeriod,
                                 webOrderLineItemId: appStoreReceipt.webOrderLineItemId,
                                 cancellationDate: appStoreReceipt.cancellationDate)
    }
}
