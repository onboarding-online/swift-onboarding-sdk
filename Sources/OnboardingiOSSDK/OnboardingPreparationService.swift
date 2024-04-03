//
//  OnboardingPreparationService.swift
//
//
//  Created by Oleg Kuplin on 25.11.2023.
//

import Foundation
import ScreensGraph

public typealias OnboardingPreparationFinishCallback = GenericResultCallback<Void>

public final class OnboardingPreparationService {
    
    
    static private var preparedOnboardingDataCache = [PreparedOnboardingData]()
    static private let serialQueue = DispatchQueue(label: "com.onboarding.online.preparation.service")
    
    private init() {  }
    
}

// MARK: - Public methods
extension OnboardingPreparationService {
    static func prepareFullOnboardingFor(projectId: String,
                                         localJSONFileName: String,
                                         env: OnboardingEnvironment = .prod,
                                         prefetchMode: OnboardingService.AssetsPrefetchMode = .waitForScreenToLoad(timeout: 0.5),
                                         finishedCallback: @escaping OnboardingPreparationFinishCallback) {
        let identifier = onboardingIdentifierFor(projectId: projectId, env: env)
        if handleOnboardingStateIfPreparingWith(identifier: identifier, callback: finishedCallback) {
            OnboardingLogger.logWarning("Attempt to prepare onboarding that is already preparing. Prepare should be called once. Project: \(projectId). localJSONFileName: \(localJSONFileName)")
            return
        }
        OnboardingLogger.logInfo(topic: .onboarding, "Will prepare onboarding for project: \(projectId). localJSONFileName: \(localJSONFileName)")

        addPreparingOnboarding(onboardingData: .init(identifier: identifier,
                                                     prefetchMode: prefetchMode,
                                                     state: .preparing))
        
        prepareFullOnboarding(projectId: projectId, env: env, prefetchMode: prefetchMode) { result in
            switch result {
            case .success:
                finishedCallback(.success(Void()))
            case .failure(let error):

                if error.errorCode == 1 {
                    prepareFullOnboarding(localJSONFileName: localJSONFileName, identifier: identifier, prefetchMode: prefetchMode, finishedCallback: finishedCallback)
                } else {
                    finishedCallback(.failure(error))
                }
            }
        }
    }
    
    static func onPreparedWithResult(projectId: String,
                                     env: OnboardingEnvironment = .prod,
                                     callback: @escaping OnboardingPreparationFinishCallback) {
        let identifier = onboardingIdentifierFor(projectId: projectId, env: env)
        if !handleOnboardingStateIfPreparingWith(identifier: identifier, callback: callback) {
            callback(.failure(.init(error: OnboardingPreparationError.attemptToSubscribedToOnboardingThatIsNotPrepared)))
        }
    }
    
    static func onboardingPreparationState(projectId: String,
                                           env: OnboardingEnvironment = .prod) -> OnboardingPreparationState {
        let identifier = onboardingIdentifierFor(projectId: projectId, env: env)
        let onboardingData = getPreparedOnboardingData(identifier: identifier)
        return onboardingData?.state ?? .notStarted
    }
    
    static func startPreparedOnboarding(projectId: String,
                                        env: OnboardingEnvironment = .prod,
                                        finishedCallback: @escaping OnboardingFinishResult) {
        let identifier = onboardingIdentifierFor(projectId: projectId, env: env)
        startOnboardingWith(identifier: identifier, env: env, finishedCallback: finishedCallback)
    }
    
    static func getScreenGraphFor(projectId: String) -> ScreensGraph? {
        serialQueue.sync {
            let identifier = onboardingIdentifierFor(projectId: projectId, env: .prod)
            let data = preparedOnboardingDataCache.first(where: { $0.identifier == identifier })
            return data?.screenGraph
        }
    }
}

// MARK: - Private methods
private extension OnboardingPreparationService {
    static func prepareFullOnboarding(localJSONFileName: String,
                                      identifier: String,
                                      prefetchMode: OnboardingService.AssetsPrefetchMode,
                                      finishedCallback: @escaping OnboardingPreparationFinishCallback) {
        do {
            let localScreenGraph = try OnboardingLoadingService.getOnboardingFromLocalJsonName(localJSONFileName)
            loadAssetsFor(screenGraph: localScreenGraph,
                          identifier: identifier,
                          prefetchMode: prefetchMode,
                          finishedCallback: finishedCallback)
        } catch {
            finishedCallback(.failure(.init(error: error)))
        }
    }
    
    static func prepareFullOnboarding(projectId: String,
                                      env: OnboardingEnvironment = .prod,
                                      prefetchMode: OnboardingService.AssetsPrefetchMode,
                                      finishedCallback: @escaping OnboardingPreparationFinishCallback) {
        let startDate = Date()
        OnboardingService.shared.eventRegistered(event: .startResourcesLoading, params: [.prefetchMode: prefetchMode, .projectId: projectId, .environment: env])

        OnboardingLoadingService.loadScreenGraphFor(projectId: projectId,
                                                    env: env) { result in
            let jsonDownloadDate = Date()
            let jsonDownloadTime = jsonDownloadDate.timeIntervalSince(startDate)
            
            switch result {
            case .success(let screenGraph):
                let identifier = onboardingIdentifierFor(projectId: projectId, env: env)
                let startAssetDownloadDate = Date()
                
                loadAssetsFor(screenGraph: screenGraph, identifier: identifier, prefetchMode: prefetchMode) { (result) in
                    let assetDownloadTime = Date().timeIntervalSince(startAssetDownloadDate)
                    OnboardingLoadingService.registerStartLoadingEvent(jsonDownloadTime: jsonDownloadTime, assetsDownloadTime: assetDownloadTime, screenGraph: screenGraph, prefetchMode: prefetchMode)
                    
                    finishedCallback(.success(Void()))
                }
                
            case .failure(let error):
                OnboardingService.shared.systemEventRegistered(event: .JSONLoadingFailure, params: [.error: error.localizedDescription])
                finishedCallback(.failure(error))
            }
        }
    }
    
    static func onboardingIdentifierFor(projectId: String, env: OnboardingEnvironment) -> String {
        let envIdentifier = envIdentifier(for: env)
        let identifier = projectId + "_" + envIdentifier
        return identifier
    }
    
    static func envIdentifier(for env: OnboardingEnvironment) -> String {
        switch env {
        case .prod:
            return "prod"
        case .qa:
            return "qa"
        }
    }
    
    static func loadAssetsFor(screenGraph: ScreensGraph,
                              identifier: String,
                              prefetchMode: OnboardingService.AssetsPrefetchMode,
                              finishedCallback: @escaping OnboardingPreparationFinishCallback) {
        let prefetchService = AssetsPrefetchService(screenGraph: screenGraph)
        
        mutatePreparedOnboardingData(identifier: identifier) { preparingOnboarding in
            preparingOnboarding.screenGraph = screenGraph
            preparingOnboarding.prefetchService = prefetchService
        }
        
        Task { @MainActor in
            do {
                switch prefetchMode {
                case .waitForAllDone:
                    try await prefetchService.prefetchAllAssets()
                case .waitForFirstDone:
                    prefetchService.startLazyPrefetching()
                    try await prefetchService.onScreenReady(screenId: screenGraph.launchScreenId)
                case .waitForScreenToLoad(let timeout):
                    prefetchService.startLazyPrefetching()
                    try await prefetchService.onScreenReady(screenId: screenGraph.launchScreenId, timeout: timeout)
                }
                
                notifyOnboardingWaitersAndClearWith(identifier: identifier, state: .ready)
            } catch {
                notifyOnboardingWaitersAndClearWith(identifier: identifier, state: .failed(error))
            }
        }
    }
    
    static func handleOnboardingStateIfPreparingWith(identifier: String,
                                                     callback: @escaping OnboardingPreparationFinishCallback) -> Bool {
        if let preparingOnboarding = getPreparedOnboardingData(identifier: identifier) {
            switch preparingOnboarding.state {
            case .notStarted, .preparing:
                mutatePreparedOnboardingData(identifier: identifier) { preparingOnboarding in
                    preparingOnboarding.waiters.append(callback)
                }
            case .ready:
                callback(.success(Void()))
            case .failed(let error):
                callback(.failure(.init(error: error)))
            }
            return true
        }
        return false
    }
    
    static func addPreparingOnboarding(onboardingData: PreparedOnboardingData) {
        serialQueue.sync {
            preparedOnboardingDataCache.append(onboardingData)
        }
    }
    
    static func isOnboardingPrepared(identifier: String) -> Bool {
        serialQueue.sync {
            preparedOnboardingDataCache.first(where: { $0.identifier == identifier })?.state == .ready
        }
    }
    
    static func getPreparedOnboardingData(identifier: String) -> PreparedOnboardingData? {
        serialQueue.sync {
            preparedOnboardingDataCache.first(where: { $0.identifier == identifier })
        }
    }
    

    
    static func mutatePreparedOnboardingData(identifier: String, block: (inout PreparedOnboardingData)->())  {
        serialQueue.sync {
            if let i = preparedOnboardingDataCache.firstIndex(where: { $0.identifier == identifier }) {
                var onboardingData = preparedOnboardingDataCache[i]
                block(&onboardingData)
                preparedOnboardingDataCache[i] = onboardingData
            }
        }
    }
    
    static func notifyOnboardingWaitersAndClearWith(identifier: String, state: OnboardingPreparationState) {
        mutatePreparedOnboardingData(identifier: identifier) { onboardingData in
            onboardingData.waiters.forEach { waiter in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        waiter(.success(Void()))
                    case .failed(let error):
                        waiter(.failure(.init(error: error)))
                    default:
                        return
                    }
                }
            }
            onboardingData.state = state
            onboardingData.waiters.removeAll()
        }
    }
    
    static func startOnboardingWith(identifier: String, env: OnboardingEnvironment?,
                                    finishedCallback: @escaping OnboardingFinishResult) {
        guard let onboardingData = getPreparedOnboardingData(identifier: identifier),
            let screenGraph = onboardingData.screenGraph else {
            finishedCallback(.failure(.init(error: OnboardingPreparationError.requestedOnboardingIsNotReady)))
            return
        }
        
        OnboardingLoadingService.registerStartEvent(env: env, responseTime: 0.0, screenGraph: screenGraph)
        
        let runConfiguration = OnboardingService.RunConfiguration(screenGraph: screenGraph,
                                                                  appearance: OnboardingService.shared.appearance ?? .default,
                                                                  launchWithAnimation: true)
        OnboardingService.shared.projectId = identifier

        OnboardingService.shared.startOnboarding(configuration: runConfiguration,
                                                 prefetchService: onboardingData.prefetchService,
                                                 finishedCallback: finishedCallback)
    }
    
    struct PreparedOnboardingData {
        let identifier: String
        let prefetchMode: OnboardingService.AssetsPrefetchMode
        var screenGraph: ScreensGraph?
        var state: OnboardingPreparationState = .notStarted
        var prefetchService: AssetsPrefetchService?
        var error: OnboardingPreparationError? = nil
        var waiters: [OnboardingPreparationFinishCallback] = []
    }
    
    enum OnboardingPreparationError: Error {
        case attemptToPrepareDifferentOnboarding
        case requestedOnboardingIsNotReady
        case attemptToSubscribedToOnboardingThatIsNotPrepared
    }
}

public enum OnboardingPreparationState: Equatable {
    case notStarted
    case preparing
    case ready
    case failed(Error)
    
    public static func == (lhs: OnboardingPreparationState, rhs: OnboardingPreparationState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted):
            return true
        case (.preparing, .preparing):
            return true
        case (.ready, .ready):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}
