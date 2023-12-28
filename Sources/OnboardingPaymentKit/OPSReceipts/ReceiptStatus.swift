//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 28.12.2023.
//

import Foundation

public enum ReceiptStatus: Int {
    /// Not decodable status
    case unknown = -2
    /// No status returned
    case none = -1
    /// valid statua
    case valid = 0
    /// The request to the App Store was not made using the HTTP POST request method.
    case jsonNotReadable = 21000
    /// The data in the receipt-data property was malformed or the service experienced a temporary issue. Try again.
    case malformedOrMissingData = 21002
    /// The receipt could not be authenticated.
    case receiptCouldNotBeAuthenticated = 21003
    /// The shared secret you provided does not match the shared secret on file for your account.
    case secretNotMatching = 21004
    /// The receipt server was temporarily unable to provide the receipt. Try again.
    case receiptServerUnavailable = 21005
    /// This receipt is valid but the subscription has expired. When this status code is returned to your server, the receipt data is also decoded and returned as part of the response. Only returned for iOS 6-style transaction receipts for auto-renewable subscriptions.
    case subscriptionExpired = 21006
    ///  This receipt is from the test environment, but it was sent to the production environment for verification. Send it to the test environment instead.
    case testReceipt = 21007
    /// This receipt is from the production environment, but it was sent to the test environment for verification. Send it to the production environment instead.
    case productionEnvironment = 21008
    /// Internal data access error. Try again later.
    case internalError = 21009
    /// The user account cannot be found or has been deleted.
    case userAccountCanNotBeFound = 21010
    
    var isValid: Bool { return self == .valid}
    
    var logDescription: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .none:
            return "none"
        case .valid:
            return "valid"
        case .jsonNotReadable:
            return "jsonNotReadable"
        case .malformedOrMissingData:
            return "malformedOrMissingData"
        case .receiptCouldNotBeAuthenticated:
            return "receiptCouldNotBeAuthenticated"
        case .secretNotMatching:
            return "secretNotMatching"
        case .receiptServerUnavailable:
            return "receiptServerUnavailable"
        case .subscriptionExpired:
            return "subscriptionExpired"
        case .testReceipt:
            return "testReceipt"
        case .productionEnvironment:
            return "productionEnvironment"
        case .internalError:
            return "internalError"
        case .userAccountCanNotBeFound:
            return "userAccountCanNotBeFound"
        }
    }
    
}
