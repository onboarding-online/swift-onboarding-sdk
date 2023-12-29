//
//  File.swift
//
//
//  Created by Oleg Kuplin on 28.12.2023.
//

import Foundation
import StoreKit

public typealias OPSTransactionResult = Result<OPSTransactionStatus, OPSTransactionError>
public typealias OPSTransactionResultCallback = (OPSTransactionResult)->()

public typealias OPSRestoreResult = Result<Void, Error>
public typealias OPSRestoreResultCallback = (OPSRestoreResult)->()

public enum OPSTransactionStatus: Sendable {
    case purchased(completeTransaction: @Sendable ()->()), deffered
}

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

public protocol OPSTransactionsManagerDelegate: AnyObject {
    func shouldAddStorePayment(_ payment: SKPayment, for product: SKProduct) -> Bool
    func didUpdateUnexpectedTransaction(_ transaction: SKPaymentTransaction, withResult result: OPSTransactionResult)
}

public extension OPSTransactionsManagerDelegate {
    func didUpdateUnexpectedTransaction(_ transaction: SKPaymentTransaction, withResult result: OPSTransactionResult) { }
}

final class OPSTransactionsManager: NSObject {
    
    private let paymentQueue = SKPaymentQueue.default()
    private var activeTransactions = ProcessesManager<OPSPaymentTransaction, OPSTransactionResult>()
    private var restoreCompletion: OPSRestoreResultCallback?
    private var uncompletedTransactions = [SKPaymentTransaction]()
    public var restoredProducts = SKProductIDs()
    public weak var delegate: OPSTransactionsManagerDelegate?

    override init() {
        super.init()
        paymentQueue.add(self)
    }
    
}

// MARK: - SKPaymentTransactionObserver
extension OPSTransactionsManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        OPSLogger.logEvent("PaymentTransactions.Did update \(transactions.count) transactions")
        for transaction in transactions {
            OPSLogger.logEvent("PaymentTransactions.\(transaction.logDescription)")
            switch (transaction.transactionState) {
            case .purchased:
                handleTransactionPurchased(transaction: transaction)
                break
            case .failed:
                handleTransactionFailed(transaction: transaction)
                break
            case .restored:
                handleTransactionRestored(transaction: transaction)
                break
            case .deferred:
                handle(transaction: transaction, withResult: .success(.deffered))
                break
            case .purchasing:
                break
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Open methods
extension OPSTransactionsManager {
    func performTransaction(transaction: OPSPaymentTransaction, completion: @escaping OPSTransactionResultCallback) {
        if let activeRequest = self.activeTransactions.processes.first(where: { $0.object == transaction }) {
            OPSLogger.logEvent("PaymentTransactions.Will add completion handlers for ongoing \(transaction.logDescription)")
            activeRequest.addHandler(completion)
        } else {
            OPSLogger.logEvent("PaymentTransactions.Will start \(transaction.logDescription)")
            let payment = SKMutablePayment(product: transaction.product)
            payment.simulatesAskToBuyInSandbox = transaction.simulatesAskToBuyInSandbox
            if transaction.quantity > 0 {
                payment.quantity = transaction.quantity
            }
            
            if #available(iOS 12.2, tvOS 12.2, OSX 10.14.4, watchOS 6.2, *) {
                if let discount = transaction.discount as? SKPaymentDiscount {
                    payment.paymentDiscount = discount
                }
            }
            
            paymentQueue.add(payment)
            activeTransactions.addProcess(.init(object: transaction, handlers: [completion]))
        }
    }
    
    func restorePurchases(completion: @escaping OPSRestoreResultCallback) {
        OPSLogger.logEvent("PaymentTransactions.Will restore purchases")
        restoredProducts.removeAll()
        self.restoreCompletion = completion
        paymentQueue.restoreCompletedTransactions()
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        restoreCompletion?(.failure(error))
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        restoreCompletion?(.success(Void()))
    }
    
    func canCompleteTransactionWithId(_ transactionId: String) -> Bool {
        uncompletedTransactions.first(where: { $0.transactionIdentifier == transactionId }) != nil
    }
    
    func completeTransactionWithId(_ transactionId: String) -> Result<Void, OPSTransactionError> {
        if let transaction = uncompletedTransactions.first(where: { $0.transactionIdentifier == transactionId }) {
            OPSLogger.logEvent("PaymentTransactions.Will finish uncompleted transaction \(transaction.logDescription)")
            paymentQueue.finishTransaction(transaction)
            return .success(Void())
        } else {
            OPSLogger.logEvent("PaymentTransactions.Did not find uncompleted transaction with id \(transactionId)")
            return .failure(OPSTransactionError.notFound)
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        delegate?.shouldAddStorePayment(payment, for: product) ?? false
    }
    
}

// MARK: - Private methods
private extension OPSTransactionsManager {
    
    func handleTransactionPurchased(transaction: SKPaymentTransaction) {
        OPSLogger.logEvent("PaymentTransactions.Will handle Purchased \(transaction.logDescription)")
        handle(transaction: transaction, withResult: .success(.purchased(completeTransaction: { [weak self] in
            OPSLogger.logEvent("PaymentTransactions.Will finish Purchased \(transaction.logDescription)")
            self?.paymentQueue.finishTransaction(transaction)
        })))
    }

    func handleTransactionRestored(transaction: SKPaymentTransaction) {
        OPSLogger.logEvent("PaymentTransactions.Will handle Restored \(transaction.logDescription)")
        restoredProducts.insert(transaction.payment.productIdentifier)
        paymentQueue.finishTransaction(transaction)
    }

    func handleTransactionFailed(transaction: SKPaymentTransaction) {
        if let transactionError = transaction.error as NSError? {
            if transactionError.code != SKError.paymentCancelled.rawValue {
                OPSLogger.logEvent("PaymentTransactions.Error \(transactionError.localizedDescription) for \(transaction.logDescription)")
                handle(transaction: transaction, withResult: .failure(.other(message: transactionError.localizedDescription)))
            } else {
                OPSLogger.logEvent("PaymentTransactions.Cancelled \(transaction.logDescription)")
                handle(transaction: transaction, withResult: .failure(.cancelled))
            }
        } else {
            OPSLogger.logEvent("PaymentTransactions.Very very strange error without description for \(transaction.logDescription)")
            handle(transaction: transaction, withResult: .failure(.other(message: "Something weird happened")))
        }
    }
    
    func handle(transaction: SKPaymentTransaction, withResult result: OPSTransactionResult) {
        DispatchQueue.main.async { [weak self] in
            func completeTransaction() {
                OPSLogger.logEvent("PaymentTransactions.Will complete \(transaction.logDescription)")
                self?.paymentQueue.finishTransaction(transaction)
            }
            
            func notifyWaitersAndCompleteTransaction() {
                if let paymentTransaction = self?.activeTransactions.objectWhere({ $0.product.productIdentifier == transaction.payment.productIdentifier }) {
                    if paymentTransaction.autoComplete || transaction.transactionState == .failed {
                        completeTransaction()
                    } else {
                        self?.uncompletedTransactions.append(transaction)
                    }
                    OPSLogger.logEvent("PaymentTransactions.Will notify waiters for \(transaction.logDescription) with result \(result)")
                    self?.activeTransactions.completeWhere({ $0.product.productIdentifier == transaction.payment.productIdentifier }, withResult: result)
                } else {
                    if transaction.transactionState == .failed {
                        completeTransaction()
                    } else {
                        OPSLogger.logEvent("PaymentTransactions.No waiters for \(transaction.logDescription) with result \(result). Add to uncompleted transactions. Uncompleted transactions count: \((self?.uncompletedTransactions.count ?? 0) + 1)")
                        self?.uncompletedTransactions.append(transaction)
                        self?.delegate?.didUpdateUnexpectedTransaction(transaction, withResult: result)
                    }
                }
            }
            
            switch result {
            case .success(let status):
                switch status {
                case .deffered:
                    if let process = self?.activeTransactions.processWhere({ $0.product.productIdentifier == transaction.payment.productIdentifier }) {
                        OPSLogger.logEvent("PaymentTransactions.Will notify about deffered \(transaction.logDescription). Ask to buy flow starts here.")
                        process.notifyWaiters(result: result)
                    }
                default:
                    notifyWaitersAndCompleteTransaction()
                }
            default:
                notifyWaitersAndCompleteTransaction()
            }
        }
    }
    
}

