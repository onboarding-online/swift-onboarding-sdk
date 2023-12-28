//
//  File.swift
//
//
//  Created by Oleg Kuplin on 28.12.2023.
//

import Foundation
import StoreKit

typealias ReceiptProperties = [String : Any]

final class OPSRefreshReceiptRequest: NSObject {
    
    let refreshReceiptRequest: SKReceiptRefreshRequest
    let callback: OPSEmptyResultCallback
    
    init(receiptProperties: ReceiptProperties? = nil, callback: @escaping OPSEmptyResultCallback) {
        self.callback = callback
        self.refreshReceiptRequest = SKReceiptRefreshRequest(receiptProperties: receiptProperties)
        super.init()
        self.refreshReceiptRequest.delegate = self
    }
    
    func start() {
        self.refreshReceiptRequest.start()
    }
    
    func cancel() {
        self.refreshReceiptRequest.cancel()
    }
    
}

// MARK: - SKRequestDelegate
extension OPSRefreshReceiptRequest: SKRequestDelegate {
    
    func requestDidFinish(_ request: SKRequest) {
        callback(.success(Void()))
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        // XXX could here check domain and error code to return typed exception
        callback(.failure(error))
    }
    
}
