//
//  File.swift
//  
//  Copyright 2023 Onboarding.online. All rights reserved.
//

import Foundation

public enum ONetworkError: LocalizedError {
    case badURL, badHTML
    case badRequest, unauthorized, forbidden, notFound, methodNotAllowed, notAcceptable, requestTimeout, conflict
    case noData
    case serverError(code: Int)
    case decodingError(message: String)
    case other(message: String)
    
    static func fromError(_ error: Error) -> ONetworkError {
        if let networkError = error as? ONetworkError {
            return networkError
        } else if let error = error as? DecodingError {
            return decodingErrorFrom(error: error)
        }
        
        let nsError = error as NSError
        let code = nsError.code
        
        if let networkError = errorForCode(code) {
            return networkError
        }
        
        return .other(message: nsError.localizedDescription)
    }
    
    static func errorForCode(_ code: Int) -> ONetworkError? {
        switch code {
        case 400: return .badRequest
        case 401: return .unauthorized
        case 403: return .forbidden
        case 404: return .notFound
        case 405: return .methodNotAllowed
        case 406: return .notAcceptable
        case 408: return .requestTimeout
        case 500...599: return .serverError(code: code)
        default: return nil
        }
    }
    
    private static func decodingErrorFrom(error: DecodingError) -> ONetworkError {
        switch error {
        case .typeMismatch(_, let context), .keyNotFound(_, let context), .valueNotFound(_, let context), .dataCorrupted(let context):
            return .decodingError(message: context.debugDescription)
        default:
            return .decodingError(message: error.localizedDescription)
        }
    }
}

extension ONetworkError {
    public var errorDescription: String? {
        switch self {
        case .badURL:
            return "Bad URL"
        case .badHTML:
            return "Bad HTML"
        case .badRequest:
            return "Bad request"
        case .unauthorized:
            return "Not authorised"
        case .forbidden:
            return "Forbidden"
        case .notFound:
            return "Not Found"
        case .methodNotAllowed:
            return "Method not allowed"
        case .notAcceptable:
            return "Not acceptable"
        case .requestTimeout:
            return "Request time out"
        case .noData:
            return "No data"
        case .conflict:
            return "Conflict"
        case .serverError(let code):
            return "Server error \(code)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        case .other(let message):
            return message
        }
    }
}
