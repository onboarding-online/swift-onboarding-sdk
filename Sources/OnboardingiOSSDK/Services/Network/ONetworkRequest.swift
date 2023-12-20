//
//  File.swift
//  
//  Onboarding.online
//  Copyright 2023 Onboarding.online. All rights reserved.
//

import Foundation

public typealias ONetworkRequestParameters = [String : Any]
public typealias OHTTPHeaders = [String : String]

public extension OHTTPHeaders {
    static func BasicAuthorization(username: String, password: String) -> OHTTPHeaders {
        let loginString = "\(username):\(password)"
        guard let loginData = loginString.data(using: String.Encoding.utf8) else { return [:] }
        let base64LoginString = loginData.base64EncodedString()
        
        return ["Authorization" : "Basic \(base64LoginString)"]
    }
    
    static func BearerAuthorization(token: String) -> OHTTPHeaders {
        return ["Authorization" : "Bearer \(token)"]
    }
}

public enum OHTTPMethod: String {
    case GET
    case PUT
    case ACL
    case HEAD
    case POST
    case COPY
    case LOCK
    case MOVE
    case BIND
    case LINK
    case PATCH
    case TRACE
    case MKCOL
    case MERGE
    case PURGE
    case NOTIFY
    case SEARCH
    case UNLOCK
    case REBIND
    case UNBIND
    case REPORT
    case DELETE
    case UNLINK
    case CONNECT
    case MSEARCH
    case OPTIONS
    case PROPFIND
    case CHECKOUT
    case PROPPATCH
    case SUBSCRIBE
    case MKCALENDAR
    case MKACTIVITY
    case UNSUBSCRIBE
    case SOURCE
}

public enum ONetworkPostDataType {
    case json, x_www_form_urlencoded
    
    var contentType: String {
        switch self {
        case .json:
            return "application/json"
        case .x_www_form_urlencoded:
            return "application/x-www-form-urlencoded"
        }
    }
}

public struct ONetworkRequest {
    
    let url: String
    public var postDataType: ONetworkPostDataType = .json
    public var httpMethod: OHTTPMethod = .GET
    public var data: Any? = nil
    public var resultQueue: DispatchQueue = .main
    public var headers: OHTTPHeaders = [:]
    
    public init(url: String,
                postDataType: ONetworkPostDataType = .json,
                httpMethod: OHTTPMethod = .GET,
                data: Any? = nil,
                resultQueue: DispatchQueue = .main,
                headers: OHTTPHeaders = [:]) {
        self.url = url
        self.postDataType = postDataType
        self.httpMethod = httpMethod
        self.data = data
        self.resultQueue = resultQueue
        self.headers = headers
    }
    
    var urlString: String {
        var urlString = url
        if httpMethod == .GET,
           let data = self.data as? ONetworkRequestParameters {
            
            urlString += "?"
            urlString += data.map({ "\($0.key)=\($0.value)".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "" }).joined(separator: "&")
        }
        return urlString
    }
    
    var httpBody: Data? {
        if httpMethod != .GET,
           let data = self.data as? ONetworkRequestParameters {
            switch postDataType {
            case .json:
                return try? JSONSerialization.data(withJSONObject: data, options: [])
            case .x_www_form_urlencoded:
                return data.map({ "\($0.key)=\($0.value)" }).joined(separator: "&").data(using: .utf8)
            }
        }
        return data as? Data
    }
    
    func describeSelf() {
        OnboardingLogger.logInfo(topic: .network, """

>>>>>>>> Network Request <<<<<<<<
Will make network request to:
URL: \(url)
Method: \(httpMethod.rawValue)
Headers: \(headers)
Data: \(data ?? "Nil")
Return on main thread: \(resultQueue == .main)
^^^^^^^^ Network Request ^^^^^^^^

""")
    }
    
}
