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

enum IntegrationType: String, Codable  {
    case appsflyer
    case appleSearchAds
    case adjust
    case branch
    case custom
    
    static func allCases() -> [IntegrationType] {
        return [.custom]
    }
}

struct AttributionData {
    let source: IntegrationType
    let networkUserId: String?
    let attribution: [AnyHashable: Any]
}


import Foundation

class AttributionStorageManager {
    
    // Сохранение данных атрибуции
    static func saveAttributionData(_ data: [AnyHashable: Any], for source: IntegrationType) {
        let defaults = UserDefaults.standard
        let key = "AttributionData_\(source.rawValue)"
        defaults.set(data, forKey: key)
    }
    
    // Извлечение данных атрибуции для заданной системы
    static func getAttributionData(for source: IntegrationType) -> [AnyHashable: Any]? {
        let defaults = UserDefaults.standard
        let key = "AttributionData_\(source.rawValue)"
        return defaults.dictionary(forKey: key)
    }
    
    // Отправка информации о покупке вместе с атрибуционными данными на сервер
    static func sendPurchaseWithAttributionData(purchaseInfo: PurchaseInfo, completion: @escaping (Error?) -> Void) {
        let apiManager = APIManager()
        var allAttributionData: [AttributionData] = []
        
        // Проходим по всем типам атрибуции и собираем данные
        IntegrationType.allCases().forEach { source in
            if let attributionData = getAttributionData(for: source) {
                let attribution = AttributionData(source: source, networkUserId: nil, attribution: attributionData)
                allAttributionData.append(attribution)
            }
        }
        
        // Подготовка данных покупки
        let purchaseAttributes: [String: Any] = [
            "userId": purchaseInfo.userId,
            "transactionId": purchaseInfo.transactionId,
            "amount": purchaseInfo.amount,
            "currency": purchaseInfo.currency
        ]
        
        // Объединение данных покупки с атрибуционными данными для отправки
        apiManager.updateAttributions(profileId: purchaseInfo.userId, attributions: allAttributionData, purchaseAttributes: purchaseAttributes) { error in
            completion(error)
        }
    }
}


// Менеджер для ведения логов
class LoggerManager {
    static func logMessage(_ message: String) {
        print(message) // Пример, используйте вашу систему логирования
    }
}


// API менеджер для взаимодействия с сервером (заглушка)
class APIManager {
    func updateAttribution(profileId: String, params: [String: Any], completion: @escaping (Error?) -> Void) {
        // Реализуйте отправку данных на ваш сервер
        completion(nil)
    }
}

extension APIManager {
    
    func updateAttributions(profileId: String, attributions: [AttributionData], purchaseAttributes: [String: Any], completion: @escaping (Error?) -> Void) {
        // Адрес сервера и настройка запроса
        let url = URL(string: "https://yourserver.com/api/purchases")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Формирование тела запроса
        let payload: [String: Any] = [
            "profileId": profileId,
            "purchase": purchaseAttributes,
            "attributions": attributions.map { attributionData -> [String: Any] in
                [
                    "source": attributionData.source.rawValue,
                    "attribution": attributionData.attribution,
                    "networkUserId": attributionData.networkUserId ?? ""
                ]
            }
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            request.httpBody = jsonData
            
            // Отправка запроса
            URLSession.shared.dataTask(with: request) { data, response, error in
                completion(error)
            }.resume()
        } catch {
            completion(error)
        }
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


struct PurchaseInfo: Codable {
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

    init(from decoder: Decoder) throws {
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

    func encode(to encoder: Encoder) throws {
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
        init(uuid: String = UUID().uuidString,
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


class AnalyticsService {

}
