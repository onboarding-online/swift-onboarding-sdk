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
    
    private var refreshReceiptRequest: SKReceiptRefreshRequest?
    private var callback: OPSEmptyResultCallback?
    
    @available(*, renamed: "refreshReceipt(receiptProperties:)")
    func refreshReceipt(receiptProperties: ReceiptProperties? = nil, callback: @escaping OPSEmptyResultCallback) {
        self.callback = callback
        let refreshReceiptRequest = SKReceiptRefreshRequest(receiptProperties: receiptProperties)
        refreshReceiptRequest.delegate = self
        self.refreshReceiptRequest = refreshReceiptRequest
        
        refreshReceiptRequest.start()
    }
    
    func refreshReceipt(receiptProperties: ReceiptProperties? = nil) async throws {
        try await withCheckedThrowingContinuation { continuation in
            refreshReceipt(receiptProperties: receiptProperties) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    private func cancel() {
        refreshReceiptRequest?.cancel()
    }
    
}

// MARK: - SKRequestDelegate
extension OPSRefreshReceiptRequest: SKRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {
        callback?(.success(Void()))
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        // XXX could here check domain and error code to return typed exception
        callback?(.failure(error))
    }
}
