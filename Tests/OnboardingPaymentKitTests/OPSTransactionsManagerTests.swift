//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 29.12.2023.
//

import XCTest
import StoreKit
@testable import OnboardingPaymentKit

final class OPSTransactionsManagerTests: XCTestCase {
    
    private var mockQueue: MockOPSPaymentQueue!
    private var mockDelegate: MockOPSTransactionsManagerDelegate!
    private var transactionsManager: OPSTransactionsManagerProtocol!
    
    override func setUp() async throws {
        mockQueue = MockOPSPaymentQueue()
        mockDelegate = MockOPSTransactionsManagerDelegate()
        transactionsManager = OPSTransactionsManager(paymentQueue: mockQueue)
        transactionsManager.delegate = mockDelegate
    }
    
    func testObserverSet() {
        XCTAssertTrue(mockQueue.isObserverSet())
    }
    
    func testRestoreSuccess() {
        let expectation = expectation(description: "Restore finished expectation")
        
        transactionsManager.restorePurchases { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure:
                fatalError("Failed to restore")
            }
        }
        
        waitForExpectations(timeout: 0.2, handler: { error in })
    }
    
    func testRestoreFailed() {
        let expectation = expectation(description: "Restore finished expectation")
        
        mockQueue.shouldFailRestore = true
        transactionsManager.restorePurchases { result in
            switch result {
            case .success:
                fatalError("Restore should fail")
            case .failure:
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 0.2, handler: { error in })
    }
    
    func testPurchasingStatus() {
        let expectation = expectation(description: "Transaction handled expectation")
        let productId = "1"
        var didPassCallback = false
        let ospTransaction = createOSPTransaction(productId: productId)
        let purchasingTransaction = createSKTransaction(productId: productId, state: .purchasing)

        transactionsManager.performTransaction(transaction: ospTransaction) { result in
            didPassCallback = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        mockQueue.updatedTransactions([purchasingTransaction])
        
        waitForExpectations(timeout: 0.2, handler: { error in
            XCTAssertFalse(didPassCallback)
        })
    }
    
    func testPurchasedStatusAuthCompleted() {
        let expectation = expectation(description: "Transaction handled expectation")
        let productId = "1"
        let ospTransaction = createOSPTransaction(productId: productId, autoComplete: true)
        let purchasedTransaction = createSKTransaction(productId: productId, state: .purchased)

        transactionsManager.performTransaction(transaction: ospTransaction) { result in
            switch result {
            case .success(let status):
                switch status {
                case .purchased:
                    XCTAssertEqual([purchasedTransaction], self.mockQueue.completedTransactions)
                case .deffered:
                    fatalError("Transaction should be purchased")
                }
            case .failure:
                fatalError("Transaction should success")
            }
            expectation.fulfill()
        }
        
        mockQueue.updatedTransactions([purchasedTransaction])
        
        waitForExpectations(timeout: 0.2, handler: { _ in  })
    }
    
    func testPurchasedStatusNotAuthCompleted() {
        let expectation = expectation(description: "Transaction handled expectation")
        let productId = "1"
        let ospTransaction = createOSPTransaction(productId: productId, autoComplete: false)
        let purchasedTransaction = createSKTransaction(productId: productId, state: .purchased)
        
        transactionsManager.performTransaction(transaction: ospTransaction) { result in
            switch result {
            case .success(let status):

                switch status {
                case .purchased(let completeBlock):
                    XCTAssertEqual([], self.mockQueue.completedTransactions)
                    XCTAssertTrue(self.transactionsManager.canCompleteTransactionWithId(purchasedTransaction.transactionIdentifier!))
                    completeBlock()
                    XCTAssertFalse(self.transactionsManager.canCompleteTransactionWithId(purchasedTransaction.transactionIdentifier!))
                    XCTAssertEqual([purchasedTransaction], self.mockQueue.completedTransactions)
                case .deffered:
                    fatalError("Transaction should be purchased")
                }
            case .failure:
                fatalError("Transaction should success")
            }
            expectation.fulfill()
        }
        
        mockQueue.updatedTransactions([purchasedTransaction])
        
        waitForExpectations(timeout: 0.2, handler: { _ in  })
    }
    
    func testUnhandledPurchasedStatus() {
        let expectation = expectation(description: "Transaction handled expectation")
        let productId = "1"
        let purchasedTransaction = createSKTransaction(productId: productId, state: .purchased)
        let transactionId = purchasedTransaction.transactionIdentifier!
        
        mockQueue.updatedTransactions([purchasedTransaction])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual([], self.mockQueue.completedTransactions)
            XCTAssertEqual([purchasedTransaction], self.mockDelegate.unexpectedTransactions)
            XCTAssertTrue(self.transactionsManager.canCompleteTransactionWithId(transactionId))
            
            _ = self.transactionsManager.completeTransactionWithId(transactionId)
            
            XCTAssertEqual([purchasedTransaction], self.mockQueue.completedTransactions)
            XCTAssertFalse(self.transactionsManager.canCompleteTransactionWithId(transactionId))
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 0.2, handler: { _ in  })
    }
    
    func testFailedStatus() {
        let expectation = expectation(description: "Transaction handled expectation")
        let productId = "1"
        let ospTransaction = createOSPTransaction(productId: productId)
        let failedTransaction = createSKTransaction(productId: productId, state: .failed)
        
        transactionsManager.performTransaction(transaction: ospTransaction) { result in
            switch result {
            case .success:
                fatalError("Transaction should be failed")
            case .failure:
                XCTAssertEqual([failedTransaction], self.mockQueue.completedTransactions)
            }
            expectation.fulfill()
        }
        
        mockQueue.updatedTransactions([failedTransaction])
        
        waitForExpectations(timeout: 0.2, handler: { _ in  })
    }
    
    func testUnhandledFailedStatus() {
        let expectation = expectation(description: "Transaction handled expectation")
        let productId = "1"
        let purchasedTransaction = createSKTransaction(productId: productId, state: .failed)
        let transactionId = purchasedTransaction.transactionIdentifier!
        
        mockQueue.updatedTransactions([purchasedTransaction])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual([purchasedTransaction], self.mockQueue.completedTransactions)
            XCTAssertEqual([], self.mockDelegate.unexpectedTransactions)
            XCTAssertFalse(self.transactionsManager.canCompleteTransactionWithId(transactionId))
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 0.2, handler: { _ in  })
    }
    
    func testRestoredStatus() {
        let productId = "1"
        let restoredTransaction = createSKTransaction(productId: productId, state: .restored)
        
        mockQueue.updatedTransactions([restoredTransaction])
        XCTAssertEqual([restoredTransaction], self.mockQueue.completedTransactions)
    }
    
    func testUnhandledRestoredStatus() {
        let expectation = expectation(description: "Transaction handled expectation")
        let productId = "1"
        let purchasedTransaction = createSKTransaction(productId: productId, state: .restored)
        let transactionId = purchasedTransaction.transactionIdentifier!
        
        mockQueue.updatedTransactions([purchasedTransaction])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual([purchasedTransaction], self.mockQueue.completedTransactions)
            XCTAssertEqual([], self.mockDelegate.unexpectedTransactions)
            XCTAssertFalse(self.transactionsManager.canCompleteTransactionWithId(transactionId))
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 0.2, handler: { _ in  })
    }
    
    func testDeferredStatus() {
        let expectation = expectation(description: "Transaction handled expectation")
        let productId = "1"
        let ospTransaction = createOSPTransaction(productId: productId, autoComplete: true)
        let deferredTransaction = createSKTransaction(productId: productId, state: .deferred)
        
        transactionsManager.performTransaction(transaction: ospTransaction) { result in
            switch result {
            case .success(let status):
                switch status {
                case .purchased:
                    fatalError("Transaction should be deffered")
                case .deffered:
                    XCTAssertEqual([], self.mockQueue.completedTransactions)
                }
            case .failure:
                fatalError("Transaction should success")
            }
            expectation.fulfill()
        }
        
        mockQueue.updatedTransactions([deferredTransaction])
        
        waitForExpectations(timeout: 0.2, handler: { _ in  })
    }
    
    func testUnhandledDeferredStatus() {
        let expectation = expectation(description: "Transaction handled expectation")
        let productId = "1"
        let purchasedTransaction = createSKTransaction(productId: productId, state: .deferred)
        let transactionId = purchasedTransaction.transactionIdentifier!
        
        mockQueue.updatedTransactions([purchasedTransaction])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual([], self.mockQueue.completedTransactions)
            XCTAssertEqual([], self.mockDelegate.unexpectedTransactions)
            XCTAssertFalse(self.transactionsManager.canCompleteTransactionWithId(transactionId))
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 0.2, handler: { _ in  })
    }
}

// MARK: - Private methods
private extension OPSTransactionsManagerTests {
    func createOSPTransaction(productId: String = "1", quantity: Int = 1, autoComplete: Bool = true) -> OPSPaymentTransaction {
        let product = SKProduct()
        product.setValue(productId, forKey: "productIdentifier")
        
        return OPSPaymentTransaction(product: product,
                                     discount: nil,
                                     quantity: quantity,
                                     simulatesAskToBuyInSandbox: false,
                                     autoComplete: autoComplete)
    }
    
    func createSKTransaction(productId: String,
                             state: SKPaymentTransactionState) -> SKPaymentTransaction {
        let transaction = MockSKPaymentTransaction(productId: productId, state: state)
        
        return transaction
    }
    
    func createProduct(productId: String) -> SKProduct {
        let product = SKProduct()
        product.setValue(productId, forKey: "productIdentifier")

        return product
    }
}

private final class MockSKPaymentTransaction: SKPaymentTransaction {

    private var _productId: String
    override var productId: String { _productId }
    
    init(productId: String,
         state: SKPaymentTransactionState) {
        self._productId = productId
        super.init()
        setValue(state.rawValue, forKey: "transactionState")
        setValue(UUID().uuidString, forKey: "transactionIdentifier")
    }
    
}

private final class MockOPSPaymentQueue {
    
    private var observer: SKPaymentTransactionObserver?
    
    private(set) var restoreCalled = false
    private(set) var completedTransactions: [SKPaymentTransaction] = []
    var shouldFailRestore = false
    
    func isObserverSet() -> Bool {
        observer != nil
    }
    
    func updatedTransactions(_ transactions: [SKPaymentTransaction]) {
        observer?.paymentQueue(.default(), updatedTransactions: transactions)
    }
    
    enum Error: Swift.Error {
        case any
    }
}

// MARK: - OPSPaymentQueue
extension MockOPSPaymentQueue: OPSPaymentQueue {
    func add(_ observer: SKPaymentTransactionObserver) {
        self.observer = observer
    }
    
    func add(_ payment: SKPayment) {
        
    }
    
    func restoreCompletedTransactions() {
        restoreCalled = true
        if shouldFailRestore {
            observer?.paymentQueue?(.default(), restoreCompletedTransactionsFailedWithError: Error.any)
        } else {
            observer?.paymentQueueRestoreCompletedTransactionsFinished?(.default())
        }
    }
    
    func finishTransaction(_ transaction: SKPaymentTransaction) {
        completedTransactions.append(transaction)
    }
}

private final class MockOPSTransactionsManagerDelegate: OPSTransactionsManagerDelegate {
    private(set) var unexpectedTransactions: [SKPaymentTransaction] = []
    
    func didUpdateUnexpectedPurchasedTransaction(_ transaction: SKPaymentTransaction, withResult result: OPSTransactionResult) {
        unexpectedTransactions.append(transaction)
    }

    func shouldAddStorePayment(_ payment: SKPayment, for product: SKProduct) -> Bool {
        true
    }
}
