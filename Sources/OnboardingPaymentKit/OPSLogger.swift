//
//  File.swift
//
//
//  Created by Oleg Kuplin on 28.12.2023.
//

import Foundation
import os.log
import StoreKit

public final class OPSLogger {
    
    public enum LogLevel {
        case debug, none
    }
    
    static let logger = OSLog(subsystem: "com.onboarding.payments", category: "in-app purchases")
    
    static var logLevel: LogLevel = .none
    
    static func logEvent(_ event: String) {
        if logLevel == .debug {
            os_log("%@", log: logger, type: .debug, event)
        }
    }
    
    static func logError(message: String) {
        os_log("%@", log: logger, type: .error, "Error: " + message)
    }
    
    static func logError(_ error: Error) {
        os_log("%@", log: logger, type: .error, "Error: " + error.localizedDescription)
    }
    
}
