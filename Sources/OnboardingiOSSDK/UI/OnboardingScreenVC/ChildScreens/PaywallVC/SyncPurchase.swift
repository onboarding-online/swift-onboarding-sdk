//
//  File.swift
//  
//
//  Created by Leonid Yuriev on 5.03.24.
//

import Foundation
//import AppsFlyerLib
//import FBSDKCoreKit
//import Amplitude

import AdServices
import UIKit
import AdSupport
import iAd
import Foundation


public class AttributionStorageManager {
    static let syncDate = "syncDate"
    static let transactions = "transactions"

    static let onboardingUserId = "onboardingUserId"
    static let platformUserId = "userId"
    static let platformDeviceId = "deviceId"
    
    // Сохранение данных атрибуции
    public func saveAttributionData(userId: String?, deviceId: String? = nil, data: [AnyHashable: Any]?, for platform: IntegrationType) {
        if  let date = AttributionStorageManager.getSyncDate(for: platform) {
            print("[deicline platform save, was saved at]  \(date)")
        } else {
            print("[save platform data] \(platform.rawValue)")
            if  ( platform == .Amplitude && (!(userId ?? "").isEmpty || !(deviceId ?? "").isEmpty)) || !(userId ?? "").isEmpty  {
                let defaults = UserDefaults.standard
                var params = data ?? [AnyHashable: Any]()
                if let userId = userId {
                    params[AttributionStorageManager.platformUserId] = userId
                }
                if let deviceId = deviceId {
                    params[AttributionStorageManager.platformDeviceId] = deviceId
                }
                
                let key = platform.keyForUserDefaults
                defaults.set(params, forKey: key)
            }
           
        }
    }
    
    // Отправка информации о покупке вместе с атрибуционными данными на сервер
    public func sendPurchase(projectId: String, transactionId: String,  purchaseInfo: PurchaseInfo,  completion: @escaping (Error?) -> Void) {
        let apiManager = APIManager()
        let userID =  AttributionStorageManager.createAndSaveOnceOnboarding(userId: UUID.init().uuidString)

        // Подготовка данных покупки
        let purchaseAttributes: [String: Any] = [
            "userId": purchaseInfo.userId,
            "transactionId": purchaseInfo.transactionId,
            "amount": purchaseInfo.amount,
            "currency": purchaseInfo.currency
        ]
        
        // Объединение данных покупки с атрибуционными данными для отправки
        apiManager.update(projectId: projectId, transactionId: transactionId, userId: userID, purchaseAttributes: purchaseAttributes) { error in
            completion(error)
        }
    }
    
    // Отправка информации о покупке вместе с атрибуционными данными на сервер
    public func sendIntegrationsDetails(projectId: String, completion: @escaping (Error?) -> Void) {
        let apiManager = APIManager()
        var allAttributionData: [AttributionData] = []
        
        // Проходим по всем типам атрибуции и собираем данные
        IntegrationType.allCases.forEach { source in
            if let attributionData = AttributionStorageManager.getAttributionData(for: source) {
                if AttributionStorageManager.getSyncDate(for: source) == nil {
                    let userId = attributionData[AttributionStorageManager.platformUserId] as? String
                    let deviceId = attributionData[AttributionStorageManager.platformDeviceId] as? String

                    let attribution = AttributionData(platform: source, platformUserId: userId, deviceUserId: deviceId, attribution: attributionData)
                    allAttributionData.append(attribution)
                }
            }
        }
        
        apiManager.sendAttributions(projectId: projectId, attributions: allAttributionData) { (userID, error) in
            AttributionStorageManager.updateSyncDate()
            completion(error)
        }
    }
    
    public static func updateSyncDate() {
        let date = Date()
        let defaults = UserDefaults.standard
        
        // Проходим по всем типам атрибуции и собираем данные
        IntegrationType.allCases.forEach { platform in
            if AttributionStorageManager.getSyncDate(for: platform) == nil {
                if var attributionData = AttributionStorageManager.getAttributionData(for: platform) {
                    attributionData[AttributionStorageManager.syncDate]  = date
                    let key = platform.keyForUserDefaults
                    defaults.set(attributionData, forKey: key)
                    
                }
            }
        }
    }
    
    
    // Сохранение данных атрибуции
    public static func createAndSaveOnceOnboarding(userId: String) -> String {
        if AttributionStorageManager.getOnboardingUserId() == nil {
            let defaults = UserDefaults.standard
            let onboardingUserAttributes: [String: Any] = [AttributionStorageManager.onboardingUserId: userId]
            
            let key = AttributionStorageManager.onboardingUserId
            defaults.set(onboardingUserAttributes, forKey: key)
        }
        return getOnboardingUserId() ?? ""
    }
    
    // Извлечение данных атрибуции для заданной системы
    public static func getOnboardingUserId() -> String? {
        let defaults = UserDefaults.standard
        let key = AttributionStorageManager.onboardingUserId
        let dict =  defaults.dictionary(forKey: key)
        let id = dict?[AttributionStorageManager.onboardingUserId] as? String
        return id
    }
    
    // Сохранение данных атрибуции
    public static func saveUserIdSyncDate(date: Date? = Date()) {
        if AttributionStorageManager.getUserIdSyncDate() == nil {
            let defaults = UserDefaults.standard
            let key = AttributionStorageManager.onboardingUserId
            if var params = defaults.dictionary(forKey: key) {
                params[AttributionStorageManager.syncDate] = Date()
                defaults.set(params, forKey: key)
            }
        }
    }
}
    


class APIManager {
    
    func update(projectId: String, transactionId: String, userId: String, purchaseAttributes: [String: Any], completion: @escaping (Error?) -> Void) {
        // Адрес сервера и настройка запроса
        
        let url = URL(string: APIManager.buildURL())!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(projectId, forHTTPHeaderField: "X-API-Key")

        // Формирование тела запроса
        let payload: [String: Any] = [
            "transactionId": transactionId,
            "userId": userId,
            "transactionDetails" : purchaseAttributes
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)

            print("[transaction_info] platform data \(jsonString ?? "")")

            request.httpBody = jsonData
            
            // Отправка запроса
            URLSession.shared.dataTask(with: request) { data, response, error in
                print(response)
                if error == nil, let response = response as? HTTPURLResponse {
                    switch response.statusCode {
                    case 200, 201:
                        AttributionStorageManager.updateSyncDate()
                    default:
                        break
                    }
                }
                completion(error)
            }.resume()
        } catch {
            completion(error)
        }
    }
    
    func sendAttributions(projectId: String, attributions: [AttributionData], completion: @escaping (String?, Error?) -> Void) {
        if let userId = AttributionStorageManager.getOnboardingUserId(), let syncDate = AttributionStorageManager.getUserIdSyncDate() {
            updateAttributions(userId: userId, projectId: projectId, attributions: attributions, completion: completion)
        } else {
            createAttributions(projectId: projectId, attributions: attributions, completion: completion)
        }
    }
    
    func updateAttributions(userId: String, projectId: String, attributions: [AttributionData], completion: @escaping (String?, Error?) -> Void) {
        // Адрес сервера и настройка запроса
        let rawUrl = APIManager.buildURlForAttributionSync() + "/\(userId)"

        let url = URL(string: rawUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(projectId, forHTTPHeaderField: "X-API-Key")

        var platformDict = Dictionary<String, Any>()
        for platform in attributions {
            platformDict[platform.platform.rawValue] = ["platformUserId" : platform.platformUserId, "platformDeviceId" : platform.deviceUserId]
        }
        
        
        let payload: Dictionary<String, Any> = platformDict

        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)
            
            request.httpBody = jsonData
            
            // Отправка запроса
            URLSession.shared.dataTask(with: request) { data, response, error in
                print("[update user] platform data \(jsonString ?? "") --- \(response)")
                if error == nil, let response = response as? HTTPURLResponse {
                    switch response.statusCode {
                    case 200, 201:
                        AttributionStorageManager.updateSyncDate()
                    default:
                        break
                    }
                    
                }
                completion(nil, error)
            }.resume()
        } catch {
            completion(nil, error)
        }
    }
    
    func createAttributions(projectId: String, attributions: [AttributionData], completion: @escaping (String?, Error?) -> Void) {
        // Адрес сервера и настройка запроса
        let rawUrl = APIManager.buildURlForAttributionSync()

        let url = URL(string: rawUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(projectId, forHTTPHeaderField: "X-API-Key")

        var platformDict = Dictionary<String, Any>()
        for platform in attributions {
            platformDict[platform.platform.rawValue] = ["platformUserId" : platform.platformUserId, "platformDeviceId" : platform.deviceUserId]
        }
        
        
        let userId = AttributionStorageManager.createAndSaveOnceOnboarding(userId: UUID.init().uuidString)

        let payload: Dictionary<String, Any> = ["userId": userId, "userAnalyticsData" : platformDict]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)
            
            request.httpBody = jsonData
            
            // Отправка запроса
            URLSession.shared.dataTask(with: request) { data, response, error in
                print("[create user] platform data \(jsonString ?? "") --- \(response)")
                if error == nil, let response = response as? HTTPURLResponse {
                    switch response.statusCode {
                    case 200, 201:
                        AttributionStorageManager.saveUserIdSyncDate()
                        AttributionStorageManager.updateSyncDate()

                    default:
                        break
                    }
                    
                }
                completion(nil, error)
            }.resume()
        } catch {
            completion(nil, error)
        }
    }
    
    
    static func buildURL() -> String {
//        let host = "dev.api.onboarding.online"
//        let host = "staging.api.onboarding.online"
        let host = "api.onboarding.online"

        let baseURL = "https://\(host)/paywall-service/v1/app-store-transaction"
                
        return baseURL
    }
    
    static func buildURlForAttributionSync() -> String {
//        let host = "dev.api.onboarding.online"
        let host = "api.onboarding.online"

        let baseURL = "https://\(host)/analytics-service/v1/user"
                
        return baseURL
    }
}


extension  AttributionStorageManager {

    // Извлечение данных атрибуции для заданной системы
    static func getUserIdSyncDate() -> Date? {
        let defaults = UserDefaults.standard
        let key = AttributionStorageManager.onboardingUserId
        let params = defaults.dictionary(forKey: key)
        
        return params?[AttributionStorageManager.syncDate] as? Date
    }
    
    // Извлечение данных атрибуции для заданной системы
    static func getAttributionData(for platform: IntegrationType) -> [AnyHashable: Any]? {
        let defaults = UserDefaults.standard
        let key = platform.keyForUserDefaults
        return defaults.dictionary(forKey: key)
    }
    
    // Извлечение данных атрибуции для заданной системы
    static func getNotSyncedTransactions() -> [AnyHashable: Any]? {
        let defaults = UserDefaults.standard
        let key = AttributionStorageManager.transactions
        return defaults.dictionary(forKey: key)
    }
    
    // Извлечение данных атрибуции для заданной системы
    static func save(transactionId: String, projectId: String) {
        let defaults = UserDefaults.standard
        let key = AttributionStorageManager.transactions
        if var dict = getNotSyncedTransactions() {
            dict[transactionId] = projectId
            defaults.set(dict, forKey: key)
        }
    }
    
    public func update(transactionId: String){
        let date = Date()
        let defaults = UserDefaults.standard
        
        if var dict = AttributionStorageManager.getNotSyncedTransactions() {
            let purchase = PurchaseInfo.init(integrationType: .Custom, userId: "", transactionId: "", amount: 0.0, currency: "")

            dict.keys.forEach { transaction in
                if let transactionId = transaction as? String, let value = dict[transactionId] as? String {
                    
                    self.sendPurchase(projectId: value, transactionId: transactionId, purchaseInfo: purchase) { (error) in
                        if error == nil {
                            dict.removeValue(forKey: transaction)
                            //TODO: add removing synced transaction
                        }
                    }
                }
               
            }
         
        }
        
        // Проходим по всем типам атрибуции и собираем данные
        IntegrationType.allCases.forEach { platform in
            if AttributionStorageManager.getSyncDate(for: platform) == nil {
                if var attributionData = AttributionStorageManager.getAttributionData(for: platform) {
                    attributionData[AttributionStorageManager.syncDate]  = date
                    let key = platform.keyForUserDefaults
                    defaults.set(attributionData, forKey: key)
                    
                }
            }
        }
    }
    
    // Извлечение данных атрибуции для заданной системы
    static func getSyncDate(for platform: IntegrationType) -> Date? {
        let defaults = UserDefaults.standard
        let key = platform.keyForUserDefaults
        let params = defaults.dictionary(forKey: key)
        
        return params?[AttributionStorageManager.syncDate] as? Date
    }
    
}

class DefaultsManager {
    static let shared = DefaultsManager()
    
    private func lastSyncDateKey(for source: IntegrationType) -> String {
        return "lastSyncDate_\(source.rawValue)"
    }
    
    func getLastSyncDate(for source: IntegrationType) -> Date? {
        return UserDefaults.standard.object(forKey: lastSyncDateKey(for: source)) as? Date
    }
    
    func setLastSyncDate(_ date: Date, for source: IntegrationType) {
        UserDefaults.standard.set(date, forKey: lastSyncDateKey(for: source))
    }
}


public struct PurchaseInfo: Codable {
    var uuid: String
    var idfa: String?
    var appVersion: String?
    var appBuild: String?
    var osVersion: String
    var deviceModel: String
    var locale: String
    var timezone: String
    var integrationType: IntegrationType
    
    var userId: String
    var transactionId: String
    var amount: Double
    var currency: String
    
    enum CodingKeys: String, CodingKey {
        case uuid, idfa, appVersion, appBuild, osVersion, deviceModel, locale, timezone, integrationType, appleSearchAdsAttribution, userId, transactionId, amount, currency
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decode(String.self, forKey: .uuid)
        idfa = try container.decodeIfPresent(String.self, forKey: .idfa)
        appVersion = try container.decodeIfPresent(String.self, forKey: .appVersion)
        appBuild = try container.decodeIfPresent(String.self, forKey: .appBuild)
        osVersion = try container.decode(String.self, forKey: .osVersion)
        deviceModel = try container.decode(String.self, forKey: .deviceModel)
        locale = try container.decode(String.self, forKey: .locale)
        timezone = try container.decode(String.self, forKey: .timezone)
        integrationType = try container.decode(IntegrationType.self, forKey: .integrationType)
        
        userId = try container.decode(String.self, forKey: .userId)
        transactionId = try container.decode(String.self, forKey: .transactionId)
        amount = try container.decode(Double.self, forKey: .amount)
        currency = try container.decode(String.self, forKey: .currency)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encodeIfPresent(idfa, forKey: .idfa)
        try container.encodeIfPresent(appVersion, forKey: .appVersion)
        try container.encodeIfPresent(appBuild, forKey: .appBuild)
        try container.encode(osVersion, forKey: .osVersion)
        try container.encode(deviceModel, forKey: .deviceModel)
        try container.encode(locale, forKey: .locale)
        try container.encode(timezone, forKey: .timezone)
        try container.encode(integrationType, forKey: .integrationType)
        
        try container.encode(userId, forKey: .userId)
        try container.encode(transactionId, forKey: .transactionId)
        try container.encode(amount, forKey: .amount)
        try container.encode(currency, forKey: .currency)
    }
    
    // Инициализатор для создания нового экземпляра PurchaseInfo
    public init(uuid: String = UUID().uuidString,
             idfa: String? = nil,
             appVersion: String? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
             appBuild: String? = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
             osVersion: String = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
             deviceModel: String = UIDevice.current.model,
             locale: String = Locale.preferredLanguages.first ?? Locale.current.identifier,
             timezone: String = TimeZone.current.identifier,
             integrationType: IntegrationType,
             userId: String,
             transactionId: String,
             amount: Double,
             currency: String,
             appleSearchAdsAttribution: [String: Any]? = nil) {
            self.uuid = uuid
            self.idfa = idfa
            self.appVersion = appVersion
            self.appBuild = appBuild
            self.osVersion = osVersion
            self.deviceModel = deviceModel
            self.locale = locale
            self.timezone = timezone
            self.integrationType = integrationType
            self.userId = userId
            self.transactionId = transactionId
            self.amount = amount
            self.currency = currency
        }
}

public enum IntegrationType: String, Codable, CaseIterable  {
    case AppsFlyer
    case AppleSearchAds
    case Adjust
    case Branch
    case Amplitude

    case Custom
    
    var keyForUserDefaults: String {
        switch self {
        default:
            return "AttributionData_\(self.rawValue)"
        }
    }
}

struct AttributionData {
    let platform: IntegrationType
    let platformUserId: String?
    let deviceUserId: String?

    let attribution: [AnyHashable: Any]?
}
