//
//  OnboardingLoadingService.swift
//
//
//  Created by Oleg Kuplin on 25.11.2023.
//

import Foundation
import ScreensGraph

final class OnboardingLoadingService {
    
    static private var screenGraphsCache = [String : ScreensGraph]()
    static private let serialQueue = DispatchQueue(label: "com.onboarding.online.loading.service")
    
    static func getOnboardingFromLocalJsonName(_ localJSONFileName: String) throws -> ScreensGraph {
        let url = try getUrlFor(jsonName: localJSONFileName)
        let localScreenGraph = try getOnboardingFromLocalPath(localPath: url)
        return localScreenGraph
    }
    
    static func getOnboardingFromLocalPath(localPath: URL) throws -> ScreensGraph {
        let data = try Data(contentsOf: localPath)
        let decoder = JSONDecoder()
        return try decoder.decode(ScreensGraph.self, from: data)
    }
    
    
    static func buildURLForPaymentServer() -> String {
        let sdkVersion = ScreensGraphVersion.value
        let buildVersion = Bundle.main.releaseVersionNumber
        
        let baseURL = OnboardingServiceConfig.baseUrl

        let url = "\(baseURL)/v1/onboarding?schemaVersion=\(sdkVersion)&buildVersion=\(buildVersion)"
       
        return url
    }
    
    static func buildURL(for environment: OnboardingEnvironment) -> String {
        let sdkVersion = ScreensGraphVersion.value
        let buildVersion = Bundle.main.releaseVersionNumber
        
//        let baseURL = OnboardingServiceConfig.baseUrl
        let baseURL = OnboardingServiceConfig.baseUrl

        var url = "\(baseURL)/v1/onboarding?schemaVersion=\(sdkVersion)&buildVersion=\(buildVersion)"
        if case .qa = environment {
            url += "&stage=Qa"
        }
        
        return url
    }
    
    static func getUrlFor(jsonName: String) throws -> URL {
        guard let url = Bundle.main.url(forResource: jsonName, withExtension: "json") else {
            throw errorForWrong(jsonName: jsonName)
        }
        
        return url
    }
    
    static func registerJSONLoadedAfterTimeOutEvent(responseTime: Double) {
        systemEventRegistered(event: .JSONLoadedFromURLButTimeoutOccurred, params: [.time: responseTime])
    }
    
    static func registerSourceTypeEvent(localPath: URL, timeout: Double, screenGraph: ScreensGraph) {
        let localScreenGraphAnalyticsParams = screenGraph.screenGraphAnalyticsParams()
        let jsonName = localPath.pathComponents.last ?? " "
        var analyticParams: AnalyticsEventParameters = [ .onboardingSourceType : AnalyticsEventParams.jsonName.rawValue, .jsonName : jsonName, .prefetchMode : OnboardingService.shared.assetsPrefetchMode,  .timeout: timeout]
        
        analyticParams.merge(localScreenGraphAnalyticsParams, uniquingKeysWith: {$1})
        self.eventRegistered(event: .startOnboarding, params: analyticParams)
    }
    
    static func registerStartEvent(url: String, responseTime: Double, config: OnboardingService.RunConfiguration) {
        var analyticParams: AnalyticsEventParameters =  [.onboardingSourceType : AnalyticsEventParams.url.rawValue,
                                                         .time: responseTime, .url: url,
                                                         .prefetchMode : OnboardingService.shared.assetsPrefetchMode]
        analyticParams.merge(config.screenGraph.screenGraphAnalyticsParams(), uniquingKeysWith: {$1})
        
        eventRegistered(event: .startOnboarding, params: analyticParams)
    }
    
    static func registerStartEvent(env: OnboardingEnvironment?, responseTime: Double, screenGraph: ScreensGraph?) {
        DispatchQueue.main.async {
            
            let url = OnboardingLoadingService.buildURL(for: env ?? .prod)
            
            var analyticParams: AnalyticsEventParameters =  [.onboardingSourceType : AnalyticsEventParams.url.rawValue,
                                                             .time: responseTime, .url: url,
                                                             .prefetchMode : OnboardingService.shared.assetsPrefetchMode]
            if let screenGraph = screenGraph {
                analyticParams.merge(screenGraph.screenGraphAnalyticsParams(), uniquingKeysWith: {$1})
            }
            
            eventRegistered(event: .startOnboarding, params: analyticParams)
        }
    }
    
    static func registerStartLoadingEvent(jsonDownloadTime: Double, assetsDownloadTime: Double, screenGraph: ScreensGraph?, prefetchMode: OnboardingService.AssetsPrefetchMode) {
        DispatchQueue.main.async {
            var analyticParams: AnalyticsEventParameters =  [.jsonLoadingTime : jsonDownloadTime, .assetsLoadingTime : assetsDownloadTime,
                                                             .prefetchMode : prefetchMode]
            if let screenGraph = screenGraph {
                analyticParams.merge(screenGraph.screenGraphAnalyticsParams(), uniquingKeysWith: {$1})
            }
            
            eventRegistered(event: .jsonAndPrefetchModeAssetsLoaded, params: analyticParams)
        }
    }
    
    static func errorForWrong(jsonName: String) -> GenericError {
        let error = GenericError.init(errorCode: 1, localizedDescription: "didn't find json file \(jsonName)")
        systemEventRegistered(event: .localJSONNotFound, params: [.jsonName: jsonName])
        return error
    }
    
    static func errorPaymentServiceNotFound() -> GenericError {
        let error = GenericError.init(errorCode: 4, localizedDescription: "didn't find payment service")
        systemEventRegistered(event: .paymentServiceNotFound, params: nil)
        return error
    }
    
    static func errorJSONWithBrokenStruct(jsonName: String) -> GenericError {
        let error = GenericError.init(errorCode: 3, localizedDescription: "could not decode json \(jsonName)")
        systemEventRegistered(event: .wrongJSONStruct, params: [.jsonName: jsonName])
        return error
    }
    
    static func systemEventRegistered(event: AnalyticsEvent?, params: AnalyticsEventParameters?) {
        OnboardingService.shared.systemEventRegistered(event: event, params: params)
    }
    
    static func eventRegistered(event: AnalyticsEvent?, params: AnalyticsEventParameters?) {
        OnboardingService.shared.eventRegistered(event: event, params: params)
    }
    
   
    static func loadScreenGraphFor(projectId: String,
                                   env: OnboardingEnvironment = .prod,
                                   finishedCallback: @escaping GenericResultCallback<ScreensGraph>) {
        if let cachedScreenGraph = getCachedScreenGraphFor(projectId: projectId) {
            finishedCallback(.success(cachedScreenGraph))
            return
        }
        
        let url = buildURL(for: env)
        let headers  = ["X-API-Key" : projectId]
        let request = ONetworkRequest(url: url, httpMethod: .GET, headers: headers)
        
        ONetworkManager.shared.makeNetworkDecodableRequest(request, ofType: ScreensGraph.self) { (result) in
            switch result {
            case .success(let screenGraph):
                cacheScreenGraph(screenGraph, for: projectId)
                finishedCallback(.success(screenGraph))
            case .failure(let failure):
                let error = GenericError.init(errorCode: 1, localizedDescription: failure.errorDescription ?? " ")
                finishedCallback(.failure(error))
            }
        }
    }
    
    
    static func sendPaymentInfo(transactionId: String, projectId: String,
                                   env: OnboardingEnvironment = .prod,
                                   finishedCallback: @escaping GenericResultCallback<Bool>) {
        
        
        let url = buildURLForPaymentServer()
        let headers  = ["X-API-Key" : projectId]
        let request = ONetworkRequest(url: url, httpMethod: .GET, headers: headers)
        
        ONetworkManager.shared.makeNetworkDecodableRequest(request, ofType: Bool.self) { (result) in
            switch result {
            case .success(let isSucceess):
//                cacheScreenGraph(screenGraph, for: projectId)
                finishedCallback(.success(isSucceess))
            case .failure(let failure):
                let error = GenericError.init(errorCode: 1, localizedDescription: failure.errorDescription ?? " ")
                finishedCallback(.failure(error))
            }
        }
    }
    
    private static func getCachedScreenGraphFor(projectId: String) -> ScreensGraph? {
        serialQueue.sync { screenGraphsCache[projectId] }
    }
    
    private static func cacheScreenGraph(_ screenGraph: ScreensGraph, for projectId: String) {
        serialQueue.sync { screenGraphsCache[projectId] = screenGraph }
    }
}

// MARK: - Open methods
extension OnboardingLoadingService {
    final class LoadingState {
        private var didLoadOnboarding = false
        private var didStartOnboardingFromLocalPath = false
        private let queue = DispatchQueue(label: "com.onboardingonline.loadingstate")
        
        func shouldProceedWithLoadedOnboarding() -> Bool {
            queue.sync {
                didLoadOnboarding = true
                guard !didStartOnboardingFromLocalPath else { return false }
                
                return true
            }
        }
        
        func shouldProceedWithOnboardingFromLocalPath() -> Bool {
            queue.sync {
                guard !didLoadOnboarding else { return false }
                didStartOnboardingFromLocalPath = true
                
                return true
            }
        }
    }
    
}
