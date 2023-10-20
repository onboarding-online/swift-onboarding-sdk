import Foundation

public typealias ONetworkProgress = Double
public typealias ONetworkProgressCallback = (ONetworkProgress)->()

public enum ONetworkManagerLogLevel {
    case debug, silent
}

final public class ONetworkManager: NSObject {
    
    static public let shared = ONetworkManager()
    
    private var urlSession: URLSession!
    private let networkQueue = OperationQueue()
    private var configuration: ONetworkManagerConfiguration = ONetworkManagerConfiguration()
    private var logLevel: ONetworkManagerLogLevel = .silent
    
    override init() {
        super.init()
        networkQueue.maxConcurrentOperationCount = configuration.maxConcurrentOperationCount
        
        let sessionConfiguration = URLSessionConfiguration.default
        urlSession = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: networkQueue)
    }
}

// MARK: - Network Decodable requests
public extension ONetworkManager {
    
//    TODO: add ab-test-group, ab-test-threshold to response to check ab test info

    func makeNetworkRequest(_ request: ONetworkRequest,
                            completion: @escaping (Result<Data, ONetworkError>)->()) {
        if logLevel == .debug {
            request.describeSelf()
        }
        switch urlRequestFor(request: request) {
        case .success(let urlRequest):
            
            urlSession.dataTask(
                with: urlRequest,
                completionHandler: { (taskData: Data?, response: URLResponse?, taskError: Error?) in
                    request.resultQueue.async {
                        guard let response = response as? HTTPURLResponse,
                              let data = taskData else {
                            completion(.failure(.noData))
                            return
                        }
                        if let abTestThreshold = response.allHeaderFields["ab-test-threshold"] {
                            let abTestGroup = response.allHeaderFields["ab-test-group"] ?? " "
                            let abtestId = response.allHeaderFields["ab-test-id"] ?? " "
                            let abtestName = response.allHeaderFields["ab-test-name"] ?? " "
                            
                            OnboardingService.shared.eventRegistered(event: .abTestLoaded, params: [.abtestThreshold : abTestThreshold, .abtestGroup : abTestGroup, .abtestId : abtestId, .abtestName : abtestName])
                        }
                        
                        if response.statusCode < 300 {
                            completion(.success(data))
                        } else if let error = try? self.configuration.decoder.decode(OServerError.self, from: data) {
                            let error = ONetworkError.errorForCode(error.statusCode) ?? ONetworkError.other(message: error.message)
                            completion(.failure(error))
                        } else {
                            let error = ONetworkError.errorForCode(response.statusCode) ?? ONetworkError.noData
                            completion(.failure(error))
                        }
                    }
                }
            ).resume()
        case .failure:
            completion(.failure(.badRequest))
        }
    }
    
    func makeNetworkDecodableRequest<T: Decodable>(_ request: ONetworkRequest,
                                                   ofType type: T.Type,
                                                   completion: @escaping (Result<T, ONetworkError>)->()) {
        makeNetworkRequest(request,
                           completion: { result in
            switch result {
            case .success(let data):
                do {
                    let response = try self.configuration.decoder.decode(type, from: data)
                    completion(.success(response))
                } catch {
                    completion(.failure(ONetworkError.fromError(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
}

// MARK: - URLSessionTaskDelegate
extension ONetworkManager: URLSessionTaskDelegate { }

// MARK: - Network Configuration
public extension ONetworkManager {
    
    func setConfiguration(_ configuration: ONetworkManagerConfiguration) {
        self.configuration = configuration
        networkQueue.maxConcurrentOperationCount = configuration.maxConcurrentOperationCount
    }
    
    func setAuthorizationHeaders(_ headers: OHTTPHeaders?) {
        self.configuration.authorizationHeaders = headers
    }
    
    func setLogLevel(_ logLevel: ONetworkManagerLogLevel) {
        self.logLevel = logLevel
    }
    
}

// MARK: - Private methods
private extension ONetworkManager {
    
    func addAuthorizationToHeaders(_ headers: inout OHTTPHeaders) {
        if let authHeaders = configuration.authorizationHeaders {
            authHeaders.forEach { (key, value) in
                headers[key] = value
            }
        }
    }
    
    func urlRequestFor(request: ONetworkRequest) -> Result<URLRequest, ONetworkError> {
        let urlString = request.urlString
        guard let url = URL(string: urlString) else {
            return .failure(.badURL)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.httpMethod.rawValue
        urlRequest.httpBody = request.httpBody
        var headers = request.headers
        addAuthorizationToHeaders(&headers)
        headers["Content-Type"] = request.postDataType.contentType
        urlRequest.allHTTPHeaderFields = headers
        urlRequest.cachePolicy = .reloadIgnoringCacheData
        
        return .success(urlRequest)
    }
    
}
