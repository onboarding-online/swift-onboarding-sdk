//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 02.01.2024.
//

import Foundation

struct DefaultReceiptFetcher: OPSReceiptFetcher {
    func fetchReceipt(appStoreReceiptData: Data,
                      sharedSecret: String,
                      environment: PaymentsEnvironment,
                      completion: @escaping ((Result<Data, ReceiptError>)->())) {
        let storeURL = URL(string: urlForEnvironment(environment))!
        let storeRequest = NSMutableURLRequest(url: storeURL)
        storeRequest.httpMethod = "POST"
        
        let receipt = appStoreReceiptData.base64EncodedString(options: [])
        let requestContents: NSMutableDictionary = ["receipt-data": receipt]
        requestContents.setValue(sharedSecret, forKey: "password")
        
        // Encore request body
        do {
            storeRequest.httpBody = try JSONSerialization.data(withJSONObject: requestContents, options: [])
        } catch {
            OPSLogger.logError(message: "AppStoreReceipt.Failed to crete validate receipt request body using parameters:\n\(requestContents)")
            OPSLogger.logError(error)
            completion(.failure(.requestBodyEncodeError(error: error)))
            return
        }
        
        let task = URLSession.shared.dataTask(with: storeRequest as URLRequest) { data, _, error -> Void in
            // there is an error
            if let networkError = error {
                OPSLogger.logError(message: "AppStoreReceipt.Validate AppStore Receipt did receive network error")
                OPSLogger.logError(networkError)
                completion(.failure(.networkError(error: networkError)))
                return
            }
            
            // there is no data
            guard let data = data else {
                OPSLogger.logError(message: "AppStoreReceipt.Validate AppStore Receipt did receive response without data")
                completion(.failure(.noRemoteData))
                return
            }
            
            completion(.success(data))
        }
        task.resume()
    }
    
    private func urlForEnvironment(_ env: PaymentsEnvironment) -> String {
        switch env {
        case .production:
            return "https://buy.itunes.apple.com/verifyReceipt"
        case .sandbox:
            return "https://sandbox.itunes.apple.com/verifyReceipt"
        }
    }
}
