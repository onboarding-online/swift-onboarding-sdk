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
    private var transactionsManager: OPSTransactionsManagerProtocol!
    
    override func setUp() async throws {
        mockQueue = MockOPSPaymentQueue()
        transactionsManager = OPSTransactionsManager(paymentQueue: mockQueue)
    }
    
    func testObserverSet() {
        XCTAssertNotNil(mockQueue.observer)
    }
    
    func testPurchasingStatus() {
        let expectation = expectation(description: "Transaction handled expectation")
        
        // Assume you have an asynchronous function to test
        let productId = "1"
        var didPassCallback = false
        let ospTransaction = createOSPTransaction(productId: productId)
        transactionsManager.performTransaction(transaction: ospTransaction) { result in
            didPassCallback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        let purchasingTransaction = createSKTransaction(productId: productId, state: .purchasing)
        mockQueue.observer?.paymentQueue(.default(), updatedTransactions: [purchasingTransaction])
        
        // Wait for the expectation to be fulfilled or until the timeout occurs
        waitForExpectations(timeout: 0.2, handler: { error in
            // Optionally, handle any error that may occur (e.g., timeout)
            XCTAssertFalse(didPassCallback)
        })
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

final class MockSKPaymentTransaction: SKPaymentTransaction {
    
    private var _productId: String
    override var productId: String { _productId }
     
    init(productId: String,
         state: SKPaymentTransactionState) {
        self._productId = productId
        super.init()
        setValue(state.rawValue, forKey: "transactionState")
    }
    
}

private final class MockOPSPaymentQueue: OPSPaymentQueue {
    
    private(set) var observer: SKPaymentTransactionObserver?
    
    func add(_ observer: SKPaymentTransactionObserver) {
        self.observer = observer
    }
    
    func add(_ payment: SKPayment) {
        
    }
    
    func restoreCompletedTransactions() {
        
    }
    
    func finishTransaction(_ transaction: SKPaymentTransaction) {
        
    }
}
