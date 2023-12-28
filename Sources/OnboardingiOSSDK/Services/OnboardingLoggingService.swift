//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 20.12.2023.
//

import Foundation
import os.log

public struct OnboardingLogger {
    
    public enum Topic: String, CaseIterable {
        case onboarding
        case assetsPrefetch = "Onboarding-Assets"
        case network = "Onboarding-Network"
        case purchase = "Onboarding-Payment"
        
        case warning
        case error
    }
    
    static private var allowedTopics = Set(Topic.allCases)
    
}

// MARK: - Public methods
public extension OnboardingLogger {
    static func setAllowedTopicsSet(_ topicsSet: Set<Topic>) {
        self.allowedTopics = topicsSet
    }
}

// MARK: - Internal methods
extension OnboardingLogger {
    static func logInfo(topic: Topic, _ s: String) {
        guard isTopicAllowed(topic) else { return }
        
        log("🟩 [\(topic.rawValue)] - \(s)", logType: .info)
    }
    
    static func logWarning(_ s: String) {
        guard isTopicAllowed(.warning) else { return }
        
        log("🟨 [Warning] - \(s)", logType: .debug)
    }
    
    static func logError(_ s: String) {
        guard isTopicAllowed(.error) else { return }
        
        log("🟥 [Error] - \(s)", logType: .error)
    }
}

// MARK: - Private methods
private extension OnboardingLogger {
    static func log(_ message: String,
                    logType: OSLogType) {
        let log = OSLog(subsystem: "com.onboarding.online", category: "debug")
        os_log(logType, log: log, "%{public}s", message)
    }
    
    static func isTopicAllowed(_ topic: Topic) -> Bool {
        allowedTopics.contains(topic)
    }
}
