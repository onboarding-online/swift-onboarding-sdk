//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 29.12.2023.
//

import Foundation
import StoreKit

protocol OPSPaymentQueue {
    func add(_ observer: SKPaymentTransactionObserver)
    func add(_ payment: SKPayment)
    func restoreCompletedTransactions()
    func finishTransaction(_ transaction: SKPaymentTransaction)
}
