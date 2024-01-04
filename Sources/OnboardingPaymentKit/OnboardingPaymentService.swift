//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 28.12.2023.
//

import Foundation
import StoreKit
import OnboardingiOSSDK

public final class OnboardingPaymentService: OnboardingPaymentServiceProtocol {
    
    private static let shared = OnboardingPaymentService()
    
    private let productsmanager = OPSProductsManager(fetcher: OPSSKProductsFetcher())
    private let transactionsManager: OPSTransactionsManagerProtocol = OPSTransactionsManager(paymentQueue: SKPaymentQueue.default())
    private let receiptsManager = OPSReceiptsManager()
    
    private func fetchProductsWith(ids: SKProductIDs) async throws -> OPSProductsResponse  {
        try await productsmanager.fetchProductsWith(ids: ids)
    }
    
    private func perform(transaction: OPSPaymentTransaction, completion: @escaping OPSTransactionResultCallback) {
        transactionsManager.performTransaction(transaction: transaction, completion: completion)
    }
    
    private func restorePurchases(completion: @escaping OPSRestoreResultCallback) {
        transactionsManager.restorePurchases(completion: completion)
    }
    
    public func fetchProductsWith(ids: Set<String>) async throws -> [SKProduct] {
        let response: OPSProductsResponse = try await fetchProductsWith(ids: ids)
        return response.products
    }
    
    public func restorePurchases() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            restorePurchases() { result in
                continuation.resume(with: result)
            }
        }
    }
    
    private func refreshReceipt(forceReload: Bool) async throws {
        try await receiptsManager.refreshReceipt(forceReload: forceReload)
    }
    
    private func validateReceipt(sharedSecret: String, completion: @escaping OPSReceiptValidationResultCallback) {
        receiptsManager.validateReceipt(sharedSecret: sharedSecret, completion: completion)
    }
    
    private func canCompleteTransactionWithId(_ transactionId: String) -> Bool {
        transactionsManager.canCompleteTransactionWithId(transactionId)
    }
    
    private func completeTransactionWithId(_ transactionId: String) -> Result<Void, OPSTransactionError> {
        return transactionsManager.completeTransactionWithId(transactionId)
    }
    
    private func setSKTransactionsDelegate(_ delegate: OPSTransactionsManagerDelegate) {
        transactionsManager.delegate = delegate
    }
    
    public init() { }
    
}

// MARK: - API
extension OnboardingPaymentService {
    
    public class func setSKTransactionsDelegate(_ delegate: OPSTransactionsManagerDelegate) {
        shared.setSKTransactionsDelegate(delegate)
    }

    public class func fetchProductsWith(ids: SKProductIDs) async throws -> OPSProductsResponse {
        try await shared.fetchProductsWith(ids: ids)
    }
    
    
    public class var canMakePayments: Bool {
        SKPaymentQueue.canMakePayments()
    }
    
    @available(*, renamed: "purchaseProduct(_:quantity:shouldAutoComplete:simulatesAskToBuyInSandbox:)")
    public class func purchaseProduct(_ product: SKProduct, quantity: Int = 1, shouldAutoComplete: Bool, simulatesAskToBuyInSandbox: Bool = false, completion: @escaping OPSTransactionResultCallback) {
        let transaction = OPSPaymentTransaction(product: product, discount: nil, quantity: quantity, simulatesAskToBuyInSandbox: simulatesAskToBuyInSandbox, autoComplete: shouldAutoComplete)
        shared.perform(transaction: transaction, completion: completion)
    }
    
    public class func purchaseProduct(_ product: SKProduct, quantity: Int = 1, shouldAutoComplete: Bool, simulatesAskToBuyInSandbox: Bool = false) async throws -> OPSTransactionStatus {
        try await withCheckedThrowingContinuation { continuation in
            purchaseProduct(product, quantity: quantity, shouldAutoComplete: shouldAutoComplete, simulatesAskToBuyInSandbox: simulatesAskToBuyInSandbox) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    @available(*, renamed: "purchaseProduct(_:quantity:shouldAutoComplete:simulatesAskToBuyInSandbox:)")
    public class func purchaseProduct(_ productId: SKProductID, quantity: Int = 1, shouldAutoComplete: Bool, simulatesAskToBuyInSandbox: Bool = false, completion: @escaping OPSTransactionResultCallback) {
        Task {
            do {
                let response = try await fetchProductsWith(ids: [productId])
                if let product = response.products.first(where: { $0.productIdentifier == productId }) {
                    let transaction = OPSPaymentTransaction(product: product, discount: nil, quantity: 1, simulatesAskToBuyInSandbox: simulatesAskToBuyInSandbox, autoComplete: shouldAutoComplete)
                    shared.perform(transaction: transaction, completion: completion)
                } else {
                    completion(.failure(.other(message: "No product with id \(productId) found")))
                }
            } catch {
                completion(.failure(.other(message: error.localizedDescription)))
            }
        }
    }
    
    public class func purchaseProduct(_ productId: SKProductID, quantity: Int = 1, shouldAutoComplete: Bool, simulatesAskToBuyInSandbox: Bool = false) async throws -> OPSTransactionStatus {
        try await withCheckedThrowingContinuation { continuation in
            purchaseProduct(productId, quantity: quantity, shouldAutoComplete: shouldAutoComplete, simulatesAskToBuyInSandbox: simulatesAskToBuyInSandbox) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    @discardableResult
    public class func canCompleteTransactionWithId(_ transactionId: String) -> Bool {
        shared.canCompleteTransactionWithId(transactionId)
    }
    
    @discardableResult
    public class func completeTransactionWithId(_ transactionId: String) -> Result<Void, OPSTransactionError> {
        shared.completeTransactionWithId(transactionId)
    }
    
    @available(*, renamed: "restorePurchases()")
    public class func restorePurchases(completion: @escaping OPSRestoreResultCallback) {
        shared.restorePurchases(completion: completion)
    }
    
    public class func restorePurchases() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            restorePurchases() { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public static var localReceiptData: Data? {
        shared.receiptsManager.appStoreReceiptData
    }
    
    public static var localValidatedReceipt: AppStoreValidatedReceipt? {
        shared.receiptsManager.validatedReceipt
    }
    
    public static var restoredProducts: SKProductIDs {
        shared.transactionsManager.restoredProducts
    }
    
    public static var logLevel: OPSLogger.LogLevel {
        get { OPSLogger.logLevel }
        set { OPSLogger.logLevel = newValue }
    }
    
    public static func refreshReceipt(forceReload: Bool) async throws {
        try await shared.refreshReceipt(forceReload: forceReload)
    }
    
    @available(*, renamed: "validateReceipt(sharedSecret:)")
    public static func validateReceipt(sharedSecret: String, completion: @escaping OPSReceiptValidationResultCallback) {
        shared.validateReceipt(sharedSecret: sharedSecret, completion: completion)
    }
    
    public static func validateReceipt(sharedSecret: String) async throws -> AppStoreValidatedReceipt {
        return try await withCheckedThrowingContinuation { continuation in
            validateReceipt(sharedSecret: sharedSecret) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    
}
