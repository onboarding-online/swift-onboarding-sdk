//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 28.12.2023.
//

import Foundation

public typealias OPSReceiptValidationResult = Result<AppStoreValidatedReceipt, ReceiptError>
public typealias OPSReceiptValidationResultCallback = (OPSReceiptValidationResult) -> ()

final class OPSValidateReceiptRequest {
    
    let sharedSecret: String
    private var environment: PaymentsEnvironment = .production
    
    init(sharedSecret: String) {
        self.sharedSecret = sharedSecret
    }
    
    func urlForEnvironment(_ env: PaymentsEnvironment) -> String {
        switch env {
        case .production:
            return "https://buy.itunes.apple.com/verifyReceipt"
        case .sandbox:
            return "https://sandbox.itunes.apple.com/verifyReceipt"
        }
    }
    
    func validate(appStoreReceiptData: Data, completion: @escaping OPSReceiptValidationResultCallback) {
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
        
        OPSLogger.logEvent("AppStoreReceipt.Will start to validate AppStore Receipt for environment \(environment.rawValue), using sharedSecret: \(sharedSecret)")
        
        // Remote task
        let task = URLSession.shared.dataTask(with: storeRequest as URLRequest) { [weak self] data, _, error -> Void in
            
            // there is an error
            if let networkError = error {
                OPSLogger.logError(message: "AppStoreReceipt.Validate AppStore Receipt did receive network error")
                OPSLogger.logError(networkError)
                completion(.failure(.networkError(error: networkError)))
                return
            }
            
            // there is no data
            guard let safeData = data else {
                OPSLogger.logError(message: "AppStoreReceipt.Validate AppStore Receipt did receive response without data")
                completion(.failure(.noRemoteData))
                return
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            
            
            do {
                let receiptInfo = try decoder.decode(AppStoreValidatedReceipt.self, from: safeData)
                let receiptStatus = ReceiptStatus(rawValue: receiptInfo.status) ?? ReceiptStatus.unknown
                
                OPSLogger.logEvent("AppStoreReceipt.Successfully validated AppStore Receipt for environment \(self?.environment.rawValue ?? ""), using sharedSecret: \(self?.sharedSecret ?? "") with status: \(receiptStatus.logDescription)")
                
                if case .testReceipt = receiptStatus {
                    self?.environment = .sandbox
                    self?.validate(appStoreReceiptData: appStoreReceiptData, completion: completion)
                } else if case .productionEnvironment = receiptStatus {
                    self?.environment = .production
                    self?.validate(appStoreReceiptData: appStoreReceiptData, completion: completion)
                } else {
                    if receiptStatus.isValid {
                        completion(.success(receiptInfo))
                    } else {
                        completion(.failure(.receiptInvalid(status: receiptStatus)))
                    }
                }
            } catch {
                func jsonDecodeError() {
                    let jsonStr = String(data: safeData, encoding: String.Encoding.utf8)
                    OPSLogger.logError(message: "AppStoreReceipt.Validate AppStore Receipt failed to decode AppStoreValidatedReceipt from \(jsonStr ?? "")")
                    OPSLogger.logError(error)
                    completion(.failure(.jsonDecodeError(string: jsonStr)))
                }
                if let wrongStatus = try? decoder.decode(AppStoreWrongReceipt.self, from: safeData) {
                    let receiptStatus = ReceiptStatus(rawValue: wrongStatus.status) ?? ReceiptStatus.unknown
                    if case .testReceipt = receiptStatus {
                        self?.environment = .sandbox
                        self?.validate(appStoreReceiptData: appStoreReceiptData, completion: completion)
                    } else if case .productionEnvironment = receiptStatus {
                        self?.environment = .production
                        self?.validate(appStoreReceiptData: appStoreReceiptData, completion: completion)
                    } else {
                        jsonDecodeError()
                    }
                } else {
                    jsonDecodeError()
                }
            }
        }
        task.resume()
    }
    
}

