//
//  OnboardingService+Load.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 04.06.2023.
//

import Foundation
import ScreensGraph

extension OnboardingService {
    
    public func startOnboarding(projectId: String,
                                localJSONFileName: String,
                                env: OnboardingEnvironment = .prod,
                                useLocalJSONAfterTimeout:TimeInterval,
                                launchWithAnimation: Bool = false,
                                finishedCallback: @escaping OnboardingFinishResult) {
        if let localPath =  OnboardingService.getUrlFor(jsonName: localJSONFileName)  {
            let appearance: OnboardingService.AppearanceStyle = .default
            let loadOptions = LoadConfiguration.Options.useLocalAfterTimeout(localPath: localPath, 
                                                                             timeout: useLocalJSONAfterTimeout)
            let loadConfiguration = LoadConfiguration.init(projectId: projectId, 
                                                           options: loadOptions,
                                                           env: env,
                                                           appearance: appearance,
                                                           launchWithAnimation: launchWithAnimation)
            
            loadOnboarding(configuration: loadConfiguration, finishedCallback: finishedCallback)
        } else {
            finishedCallback(.failure(errorForWrong(jsonName: localJSONFileName)))
        }
    }

    public func loadOnboarding(configuration: OnboardingService.LoadConfiguration,
                               finishedCallback: @escaping OnboardingFinishResult) {
        let loadingState = LoadingState()
        showLoadingAssetsScreen(appearance: configuration.appearance,
                                launchWithAnimation: configuration.launchWithAnimation)
        
        downloadJSONFromServerAndStartOnboardingIfNotTimedOut(configuration: configuration, 
                                                              loadingState: loadingState, finishedCallback: finishedCallback)
        
        if configuration.needToShowOnboardingFromLocalJson() {
            startOnboardingFromJSON(configuration: configuration,
                                    loadingState: loadingState,
                                    finishedCallback: finishedCallback)
        }
    }
    
    public func startOnboardingFrom(localJSONFileName: String,
                                    launchWithAnimation: Bool = false,
                                    finishedCallback: @escaping OnboardingFinishResult) {
        guard let url =  OnboardingService.getUrlFor(jsonName: localJSONFileName) else {
            finishedCallback(.failure(errorForWrong(jsonName: localJSONFileName)))
            return
        }
        
        if let localScreenGraph = getOnboardingFromLocalPath(localPath: url) {
            let config = RunConfiguration.init(screenGraph: localScreenGraph,
                                               launchWithAnimation: launchWithAnimation)
            OnboardingService.shared.startOnboarding(configuration: config,
                                                     finishedCallback: finishedCallback)
        } else {
            finishedCallback(.failure(errorJSONWithBrokenStruct(jsonName: localJSONFileName)))
        }
    }

}

// MARK: - Private methods
private extension OnboardingService {
    
    func downloadJSONFromServerAndStartOnboardingIfNotTimedOut(configuration: OnboardingService.LoadConfiguration,
                                                               loadingState: LoadingState,
                                                               finishedCallback: @escaping OnboardingFinishResult) {
        let requestStartDate = Date()
        
        self.loadScreenGraphFor(projectId: configuration.projectId, env: configuration.env) { [weak self](result)  in
            switch result {
            case .success(let screenGraph):
                let responseTime = Date().timeIntervalSince(requestStartDate)
                
                if loadingState.shouldProceedWithLoadedOnboarding() {
                    DispatchQueue.main.async {
                        let config = RunConfiguration.init(screenGraph: screenGraph, 
                                                           appearance: configuration.appearance,
                                                           launchWithAnimation: configuration.launchWithAnimation)
                        self?.startOnboarding(configuration: config, finishedCallback: finishedCallback)
                        
                        if let url = self?.buildURL(for: configuration.env) {
                            self?.registerStartEvent(url: url, responseTime: responseTime, config: config)
                        }
                    }
                } else {
                    self?.registerJSONLoadedAfterTimeOutEvent(responseTime: responseTime)
                }
                
            case .failure(let failure):
                self?.systemEventRegistered(event: .JSONLoadingFalure, params: [.error: failure.localizedDescription])
            }
        }
    }
    
    func startOnboardingFromJSON(configuration: OnboardingService.LoadConfiguration,
                                 loadingState: LoadingState,
                                 finishedCallback: @escaping OnboardingFinishResult) {
        switch configuration.options  {
        case .useLocalAfterTimeout(let localPath, let timeout):
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {[weak self] in
                guard let strongSelf = self else { return }
                
                if let localScreenGraph = strongSelf.getOnboardingFromLocalPath(localPath: localPath) {
                    guard  loadingState.shouldProceedWithOnboardingFromLocalPath() else { return }
                    
                    strongSelf.registerSourceTypeEvent(localPath: localPath, timeout: timeout, screenGraph: localScreenGraph)
                    
                    let config = RunConfiguration.init(screenGraph: localScreenGraph,
                                                       appearance: configuration.appearance,
                                                       launchWithAnimation: configuration.launchWithAnimation)
                    strongSelf.startOnboarding(configuration: config, finishedCallback: finishedCallback)
                } else {
                    finishedCallback(.failure(strongSelf.errorJSONWithBrokenStruct(jsonName: localPath.pathComponents.last ?? " ")))
                }
            }
        default:
            let error = GenericError.init(errorCode: 2, localizedDescription: "wrong configuration option for locals json using")
            finishedCallback(.failure(error))
        }
    }
    
    func getOnboardingFromLocalPath(localPath: URL?) -> ScreensGraph? {
        guard let localPath = localPath,
              let data = try? Data(contentsOf: localPath) else { return nil }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(ScreensGraph.self, from: data)
    }
    
    func buildURL(for environment: OnboardingEnvironment) -> String {
        let sdkVersion = ScreensGraphVersion.value
        let buildVersion = Bundle.main.releaseVersionNumber
        
        let baseURL = OnboardingServiceConfig.baseUrl

        var url = "\(baseURL)/v1/onboarding?schemaVersion=\(sdkVersion)&buildVersion=\(buildVersion)"
        if case .qa = environment {
            url += "&stage=Qa"
        }
        
        return url
    }
    
    static func getUrlFor(jsonName: String) -> URL? {
        let url = Bundle.main.url(forResource: jsonName, withExtension: "json")
        
        return url
    }

    func registerJSONLoadedAfterTimeOutEvent(responseTime: Double) {
        systemEventRegistered(event: .JSONLoadedFromURLButTimeoutOccured, params: [.time: responseTime])
    }
    
    func registerSourceTypeEvent(localPath: URL, timeout: Double, screenGraph: ScreensGraph) {
        let localScreenGraphAnalyticsParams = screenGraph.screenGraphAnalyticsParams()
        let jsonName = localPath.pathComponents.last ?? " "
        var analyticParams: AnalyticsEventParameters = [ .onboardingSourceType : AnalyticsEventParams.jsonName.rawValue, .jsonName : jsonName, .prefetchMode : self.assetsPrefetchMode,  .timeout: timeout]
      
        analyticParams.merge(localScreenGraphAnalyticsParams, uniquingKeysWith: {$1})
        self.eventRegistered(event: .startOnboarding, params: analyticParams)
    }
    
    func registerStartEvent(url: String, responseTime: Double, config: RunConfiguration) {
        var analyticParams: AnalyticsEventParameters =  [.onboardingSourceType : AnalyticsEventParams.url.rawValue, .time: responseTime, .url: url, .prefetchMode : assetsPrefetchMode]
        analyticParams.merge(config.screenGraph.screenGraphAnalyticsParams(), uniquingKeysWith: {$1})

        eventRegistered(event: .startOnboarding, params: analyticParams)
    }
    
    func errorForWrong(jsonName: String) -> GenericError {
        let error = GenericError.init(errorCode: 1, localizedDescription: "didn't find json file \(jsonName)")
        systemEventRegistered(event: .localJSONNotFound, params: [.jsonName: jsonName])
        return error
    }
    
    func errorJSONWithBrokenStruct(jsonName: String) -> GenericError {
        let error = GenericError.init(errorCode: 3, localizedDescription: "could not decode json \(jsonName)")
        systemEventRegistered(event: .wrongJSONStruct, params: [.jsonName: jsonName])
        return error
    }
    
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
    
    func loadScreenGraphFor(projectId: String, env: OnboardingEnvironment = .prod,
                               finishedCallback: @escaping GenericResultCallback<ScreensGraph>) {
        let url = buildURL(for: env)
        let headers  = ["X-API-Key" : projectId]
        let request = ONetworkRequest(url: url, httpMethod: .GET, headers: headers)
        
        ONetworkManager.shared.makeNetworkDecodableRequest(request, ofType: ScreensGraph.self) { (result) in
            switch result {
            case .success(let screenGraph):
                finishedCallback(.success(screenGraph))
            case .failure(let failure):
                let error = GenericError.init(errorCode: 1, localizedDescription: failure.errorDescription ?? " ")
                finishedCallback(.failure(error))
            }
        }
    }
}


extension OnboardingService.LoadConfiguration {
    
    func needToShowOnboardingFromLocalJson() -> Bool {
        switch self.options {
        case .waitForRemote:
            return false
        default:
            return true
        }
    }
}
