//
//  OnboardingService+Load.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 04.06.2023.
//

import Foundation
import ScreensGraph

public extension OnboardingService {
    static func prepareFullOnboardingFor(projectId: String,
                                         localJSONFileName: String,
                                         env: OnboardingEnvironment = .prod,
                                         prefetchMode: OnboardingService.AssetsPrefetchMode = .waitForScreenToLoad(timeout: 0.5),
                                         finishedCallback: @escaping OnboardingPreparationFinishCallback) {
        OnboardingPreparationService.prepareFullOnboardingFor(projectId: projectId,
                                                              localJSONFileName: localJSONFileName,
                                                              env: env,
                                                              prefetchMode: prefetchMode,
                                                              finishedCallback: finishedCallback)
    }
    
    func startPreparedOnboardingWhenReady(projectId: String,
                                          localJSONFileName: String,
                                          env: OnboardingEnvironment = .prod,
                                          useLocalJSONAfterTimeout: TimeInterval,
                                          launchWithAnimation: Bool = false,
                                          finishedCallback: @escaping OnboardingFinishResult) {
        let preparationState = OnboardingPreparationService.onboardingPreparationState(projectId: projectId, env: env)
        
        func startNew() {
            startOnboarding(projectId: projectId,
                            localJSONFileName: localJSONFileName,
                            env: env,
                            useLocalJSONAfterTimeout: useLocalJSONAfterTimeout,
                            launchWithAnimation: launchWithAnimation,
                            finishedCallback: finishedCallback)
        }
        
        func startPrepared() {
            OnboardingPreparationService.startPreparedOnboarding(projectId: projectId, env: env, finishedCallback: finishedCallback)
        }
        
        
        switch preparationState {
        case .notStarted, .failed:
            startNew()
        case .preparing:
            OnboardingPreparationService.onPreparedWithResult(projectId: projectId, env: env) { result in
                switch result {
                case .success:
                    startPrepared()
                case .failure:
                    startNew()
                }
            }
        case .ready:
            startPrepared()
        }
    }
    
    func startOnboarding(projectId: String,
                         localJSONFileName: String,
                         env: OnboardingEnvironment = .prod,
                         useLocalJSONAfterTimeout: TimeInterval,
                         launchWithAnimation: Bool = false,
                         finishedCallback: @escaping OnboardingFinishResult) {
        do {
            let localPath = try OnboardingLoadingService.getUrlFor(jsonName: localJSONFileName)
            let appearance: OnboardingService.AppearanceStyle = .default
            let loadOptions = LoadConfiguration.Options.useLocalAfterTimeout(localPath: localPath,
                                                                             timeout: useLocalJSONAfterTimeout)
            let loadConfiguration = LoadConfiguration.init(projectId: projectId,
                                                           options: loadOptions,
                                                           env: env,
                                                           appearance: appearance,
                                                           launchWithAnimation: launchWithAnimation)
            
            loadOnboarding(configuration: loadConfiguration, finishedCallback: finishedCallback)
        } catch {
            finishedCallback(.failure(.init(error: error)))
        }
    }

    func loadOnboarding(configuration: OnboardingService.LoadConfiguration,
                        finishedCallback: @escaping OnboardingFinishResult) {
        let loadingState = OnboardingLoadingService.LoadingState()
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
    
    func startOnboardingFrom(localJSONFileName: String,
                             launchWithAnimation: Bool = false,
                             finishedCallback: @escaping OnboardingFinishResult) {
        do {
            let localScreenGraph = try OnboardingLoadingService.getOnboardingFromLocalJsonName(localJSONFileName)
            let config = RunConfiguration.init(screenGraph: localScreenGraph,
                                               launchWithAnimation: launchWithAnimation)
            OnboardingService.shared.startOnboarding(configuration: config,
                                                     finishedCallback: finishedCallback)
        } catch {
            finishedCallback(.failure(.init(error: error)))
        }
    }
}

// MARK: - Private methods
private extension OnboardingService {
    
    func downloadJSONFromServerAndStartOnboardingIfNotTimedOut(configuration: OnboardingService.LoadConfiguration,
                                                               loadingState: OnboardingLoadingService.LoadingState,
                                                               finishedCallback: @escaping OnboardingFinishResult) {
        let requestStartDate = Date()
        
        OnboardingLoadingService.loadScreenGraphFor(projectId: configuration.projectId, env: configuration.env) { [weak self](result)  in
            switch result {
            case .success(let screenGraph):
                let responseTime = Date().timeIntervalSince(requestStartDate)
                
                if loadingState.shouldProceedWithLoadedOnboarding() {
                    DispatchQueue.main.async {
                        let config = RunConfiguration.init(screenGraph: screenGraph,
                                                           appearance: configuration.appearance,
                                                           launchWithAnimation: configuration.launchWithAnimation)
                        self?.startOnboarding(configuration: config, finishedCallback: finishedCallback)
                        
                        let url = OnboardingLoadingService.buildURL(for: configuration.env)
                        OnboardingLoadingService.registerStartEvent(url: url, responseTime: responseTime, config: config)
                    }
                } else {
                    OnboardingLoadingService.registerJSONLoadedAfterTimeOutEvent(responseTime: responseTime)
                }
                
            case .failure(let failure):
                self?.systemEventRegistered(event: .JSONLoadingFalure, params: [.error: failure.localizedDescription])
            }
        }
    }
    
    func startOnboardingFromJSON(configuration: OnboardingService.LoadConfiguration,
                                 loadingState: OnboardingLoadingService.LoadingState,
                                 finishedCallback: @escaping OnboardingFinishResult) {
        switch configuration.options  {
        case .useLocalAfterTimeout(let localPath, let timeout):
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
                guard let strongSelf = self else { return }
                
                do {
                    let localScreenGraph = try OnboardingLoadingService.getOnboardingFromLocalPath(localPath: localPath)
                    guard  loadingState.shouldProceedWithOnboardingFromLocalPath() else { return }
                    OnboardingLoadingService.registerSourceTypeEvent(localPath: localPath, timeout: timeout, screenGraph: localScreenGraph)
                    let config = RunConfiguration.init(screenGraph: localScreenGraph,
                                                       appearance: configuration.appearance,
                                                       launchWithAnimation: configuration.launchWithAnimation)
                    strongSelf.startOnboarding(configuration: config, finishedCallback: finishedCallback)
                } catch {
                    finishedCallback(.failure(.init(error: error)))
                }
            }
        default:
            let error = GenericError.init(errorCode: 2, localizedDescription: "wrong configuration option for locals json using")
            finishedCallback(.failure(error))
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

