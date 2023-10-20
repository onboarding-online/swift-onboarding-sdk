//
//  File.swift
//  
//  Onboarding.online
//  Copyright 2023 Onboarding.online. All rights reserved.
//

import Foundation

public struct ONetworkManagerConfiguration {
    public var authorizationHeaders: OHTTPHeaders? = nil
    public var decoder: JSONDecoder = JSONDecoder()
    public var maxConcurrentOperationCount: Int = 30
    
    public init(authorizationHeaders: OHTTPHeaders? = nil, decoder: JSONDecoder = JSONDecoder(), maxConcurrentOperationCount: Int = 3) {
        self.authorizationHeaders = authorizationHeaders
        self.decoder = decoder
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
    }
}
