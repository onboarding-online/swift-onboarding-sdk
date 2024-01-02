//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 28.12.2023.
//

import Foundation

public typealias OPSReceiptValidationResult = Result<AppStoreValidatedReceipt, ReceiptError>
public typealias OPSReceiptValidationResultCallback = (OPSReceiptValidationResult) -> ()

final class OPSReceiptValidator {
    
    private let sharedSecret: String
    private let fetcher: OPSReceiptFetcher
    var environment: PaymentsEnvironment = .production
    
    init(sharedSecret: String,
         fetcher: OPSReceiptFetcher = DefaultReceiptFetcher()) {
        self.sharedSecret = sharedSecret
        self.fetcher = fetcher
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
        fetcher.fetchReceipt(appStoreReceiptData: appStoreReceiptData,
                             sharedSecret: sharedSecret,
                             environment: environment) { [weak self] result in
            switch result {
            case .success(let data):
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .iso8601
                
                do {
                    let receiptInfo = try decoder.decode(AppStoreValidatedReceipt.self, from: data)
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
                        let jsonStr = String(data: data, encoding: String.Encoding.utf8)
                        OPSLogger.logError(message: "AppStoreReceipt.Validate AppStore Receipt failed to decode AppStoreValidatedReceipt from \(jsonStr ?? "")")
                        OPSLogger.logError(error)
                        completion(.failure(.jsonDecodeError(string: jsonStr)))
                    }
                    
                    if let wrongStatus = try? decoder.decode(AppStoreWrongReceipt.self, from: data) {
                        let receiptStatus = ReceiptStatus(rawValue: wrongStatus.status) ?? ReceiptStatus.unknown
                        if case .testReceipt = receiptStatus {
                            if self?.environment == .sandbox {
                                jsonDecodeError()
                                return
                            }
                            self?.environment = .sandbox
                            self?.validate(appStoreReceiptData: appStoreReceiptData, completion: completion)
                        } else if case .productionEnvironment = receiptStatus {
                            if self?.environment == .production {
                                jsonDecodeError()
                                return
                            }
                            self?.environment = .production
                            self?.validate(appStoreReceiptData: appStoreReceiptData, completion: completion)
                        } else {
                            jsonDecodeError()
                        }
                    } else {
                        jsonDecodeError()
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func validate(appStoreReceiptData: Data) async throws -> AppStoreValidatedReceipt {
        try await withCheckedThrowingContinuation { continuation in
            validate(appStoreReceiptData: appStoreReceiptData) { result in
                continuation.resume(with: result)
            }
        }
    }
}
