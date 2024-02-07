//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 02.01.2024.
//

import Foundation

protocol OPSReceiptFetcher {
    func fetchReceipt(appStoreReceiptData: Data,
                      sharedSecret: String,
                      environment: PaymentsEnvironment,
                      completion: @escaping ((Result<Data, ReceiptError>)->()))
}
