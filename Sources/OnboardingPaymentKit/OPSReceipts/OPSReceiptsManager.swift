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
    private var validateReceiptRequest: OPSValidateReceiptRequest?
    private let CachedReceiptDataKey = "com.SwiftPaymentsKit.CachedReceiptDataKey"
    
    init(appStoreReceiptURL: URL? = Bundle.main.appStoreReceiptURL) {
        self.appStoreReceiptURL = appStoreReceiptURL
        appStoreReceiptData = cachedReceiptData
    }
    
}

// MARK: - Open methods
extension OPSReceiptsManager {
    
    func refreshReceipt(forceReload: Bool, completion: @escaping OPSEmptyResultCallback) {
        if !forceReload {
            if appStoreReceiptData != nil {
                OPSLogger.logEvent("AppStoreReceipt.Will return local app store receipt data.")
                completion(.success(Void()))
                return
            } else if let cachedReceipt = cachedReceiptData {
                OPSLogger.logEvent("AppStoreReceipt.Will return cached app store receipt data.")
                self.appStoreReceiptData = cachedReceipt
                completion(.success(Void()))
                return
            }
        }
        
        OPSLogger.logEvent("AppStoreReceipt.Will refresh AppStore Receipt data")
        refreshReceiptRequest = OPSRefreshReceiptRequest(callback: { [weak self] (result) in
            switch result {
            case .success:
                OPSLogger.logEvent("AppStoreReceipt.Successfully refreshed AppStore Receipt data")
                self?.loadAppStoreReceiptData(completion: completion)
            case .failure(let error):
                OPSLogger.logError(message: "AppStoreReceipt.Failed to refresh AppStore Receipt data")
                OPSLogger.logError(error)
                completion(.failure(error))
            }
            self?.refreshReceiptRequest = nil
        })
        refreshReceiptRequest?.start()
    }
    
    func validateReceipt(sharedSecret: String, completion: @escaping OPSReceiptValidationResultCallback) {
        if sharedSecret.isEmpty {
            OPSLogger.logError(message: "AppStoreReceipt.Wouldn't be able to validate app store receipt. Shared secret is Empty")
        }
        OPSLogger.logEvent("AppStoreReceipt.Will try to validate AppStore Receipt using sharedSecret: \(sharedSecret)")
        guard let appStoreReceiptData = self.appStoreReceiptData else {
            refreshReceipt(forceReload: false) { [weak self] (result) in
                switch result {
                case .success:
                    self?.validateReceipt(sharedSecret: sharedSecret, completion: completion)
                case .failure:
                    completion(.failure(.noReceiptData))
                }
            }
            return
        }
        
        validateReceiptRequest = OPSValidateReceiptRequest(sharedSecret: sharedSecret)
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
    
    func loadAppStoreReceiptData(completion: @escaping OPSEmptyResultCallback) {
        OPSLogger.logEvent("AppStoreReceipt.Will download AppStore receipt data.")
        WorkingQueue.async { [weak self] in
            guard let receiptDataURL = self?.appStoreReceiptURL else  {
                OPSLogger.logError(message: "AppStoreReceipt.Invalid AppStore receipt URL \(self?.appStoreReceiptURL ?? URL(fileURLWithPath: ""))")
                completion(.failure(OPSReceiptError.noReceiptData))
                return
            }
            
            do {
                let data = try Data(contentsOf: receiptDataURL)
                self?.appStoreReceiptData = data
                self?.cacheReceiptData(data)
                OPSLogger.logEvent("AppStoreReceipt.Successfully downloaded AppStore Receipt")
                completion(.success(Void()))
            } catch {
                OPSLogger.logError(message: "AppStoreReceipt.Could not load AppStore Receipt data")
                OPSLogger.logError(error)
                completion(.failure(OPSReceiptError.noReceiptData))
            }
        }
    }
    
    var cachedReceiptData: Data? { UserDefaults.standard.data(forKey: CachedReceiptDataKey) }
    
    func cacheReceiptData(_ data: Data) {
        UserDefaults.standard.set(data, forKey: CachedReceiptDataKey)
    }
    
}
