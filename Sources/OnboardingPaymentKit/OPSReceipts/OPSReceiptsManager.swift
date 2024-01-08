//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 28.12.2023.
//

import Foundation

final class OPSReceiptsManager {
    
    enum OPSReceiptError: Error {
        case noReceiptData
    }
    
    private let appStoreReceiptURL: URL?
    private(set) var appStoreReceiptData: Data?
    private(set) var validatedReceipt: AppStoreValidatedReceipt?
    private var refreshReceiptRequest: OPSRefreshReceiptRequest?
    private var validateReceiptRequest: OPSReceiptValidator?
    private let CachedReceiptDataKey = "com.SwiftPaymentsKit.CachedReceiptDataKey"
    
    init(appStoreReceiptURL: URL? = Bundle.main.appStoreReceiptURL) {
        self.appStoreReceiptURL = appStoreReceiptURL
    }
    
}

// MARK: - Open methods
extension OPSReceiptsManager {
    
    func refreshReceipt(forceReload: Bool) async throws {
        if !forceReload {
            if appStoreReceiptData != nil {
                OPSLogger.logEvent("AppStoreReceipt.Will return local app store receipt data.")
                return
            }
//            else if let cachedReceipt = cachedReceiptData {
//                OPSLogger.logEvent("AppStoreReceipt.Will return cached app store receipt data.")
//                self.appStoreReceiptData = cachedReceipt
//                return
//            }
        }
        
        OPSLogger.logEvent("AppStoreReceipt.Will refresh AppStore Receipt data")
        do {
            let refreshReceiptRequest = OPSRefreshReceiptRequest()
            try await refreshReceiptRequest.refreshReceipt()
            try await loadAppStoreReceiptData()
        } catch {
            OPSLogger.logError(message: "AppStoreReceipt.Failed to refresh AppStore Receipt data")
            OPSLogger.logError(error)
            throw error
        }
    }
    
    func validateReceipt(sharedSecret: String, completion: @escaping OPSReceiptValidationResultCallback) {
        if sharedSecret.isEmpty {
            OPSLogger.logError(message: "AppStoreReceipt.Wouldn't be able to validate app store receipt. Shared secret is Empty")
        }
        OPSLogger.logEvent("AppStoreReceipt.Will try to validate AppStore Receipt using sharedSecret: \(sharedSecret)")
        guard let appStoreReceiptData = self.appStoreReceiptData else {
            Task {
                do {
                    try await refreshReceipt(forceReload: false)
                    validateReceipt(sharedSecret: sharedSecret, completion: completion)
                } catch {
                    completion(.failure(.noReceiptData))
                }
            }
            return
        }
        
        validateReceiptRequest = OPSReceiptValidator(sharedSecret: sharedSecret)
        validateReceiptRequest?.validate(appStoreReceiptData: appStoreReceiptData, completion: { [weak self] (result) in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case .success(let receipt):
                    self?.validatedReceipt = receipt
                    completion(.success(receipt))
                case .failure(let error):
                    completion(.failure(error))
                }
                self?.validateReceiptRequest = nil
            }
        })
    }
    
}

// MARK: - Private methods
private extension OPSReceiptsManager {
    
    func loadAppStoreReceiptData() async throws{
        OPSLogger.logEvent("AppStoreReceipt.Will download AppStore receipt data.")
        
        guard let appStoreReceiptURL else  {
            OPSLogger.logError(message: "AppStoreReceipt.Invalid AppStore receipt URL")
            throw OPSReceiptError.noReceiptData
        }
        
        do {
            let data = try Data(contentsOf: appStoreReceiptURL)
            self.appStoreReceiptData = data
            self.cacheReceiptData(data)
            OPSLogger.logEvent("AppStoreReceipt.Successfully downloaded AppStore Receipt")
        } catch {
            OPSLogger.logError(message: "AppStoreReceipt.Could not load AppStore Receipt data")
            OPSLogger.logError(error)
            throw OPSReceiptError.noReceiptData
        }
    }
    
    var cachedReceiptData: Data? { UserDefaults.standard.data(forKey: CachedReceiptDataKey) }
    
    func cacheReceiptData(_ data: Data) {
        UserDefaults.standard.set(data, forKey: CachedReceiptDataKey)
    }
    
}
