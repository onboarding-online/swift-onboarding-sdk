//
//  OnboardingPreparationService.swift
//
//
//  Created by Oleg Kuplin on 25.11.2023.
//

import Foundation
import ScreensGraph

public final class OnboardingPreparationService {
    
    public typealias OnboardingPreparationFinishCallback = GenericResultCallback<Void>
    
    static private var preparedOnboardingDataCache = [PreparedOnboardingData]()
    static private let serialQueue = DispatchQueue(label: "com.onboarding.online.preparation.service")
    
    private init() {  }
    
}

// MARK: - Public methods
public extension OnboardingPreparationService {
    static func prepareFullOnboardingFor(projectId: String,
                                         localJSONFileName: String,
                                         env: OnboardingEnvironment = .prod,
                                         prefetchMode: OnboardingService.AssetsPrefetchMode = .waitForScreenToLoad(timeout: 0.5),
                                         finishedCallback: @escaping OnboardingPreparationFinishCallback) {
        let identifier = onboardingIdentifierFor(projectId: projectId, env: env)
        if handleOnboardingStateIfPreparingWith(identifier: identifier, callback: finishedCallback) {
            return
        }
        
        addPreparingOnboarding(onboardingData: .init(identifier: identifier,
                                                     prefetchMode: prefetchMode,
                                                     state: .preparing))
        
        prepareFullOnboarding(projectId: projectId, env: env, prefetchMode: prefetchMode) { result in
            switch result {
            case .success:
                finishedCallback(.success(Void()))
            case .failure(_):
                prepareFullOnboarding(localJSONFileName: localJSONFileName, identifier: identifier, prefetchMode: prefetchMode, finishedCallback: finishedCallback)
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
        startOnboardingWith(identifier: identifier, finishedCallback: finishedCallback)
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
        OnboardingLoadingService.loadScreenGraphFor(projectId: projectId,
                                                    env: env) { result in
            switch result {
            case .success(let screenGraph):
                let identifier = onboardingIdentifierFor(projectId: projectId, env: env)
                loadAssetsFor(screenGraph: screenGraph,
                              identifier: identifier,
                              prefetchMode: prefetchMode,
                              finishedCallback: finishedCallback)
            case .failure(let error):
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
        
        switch prefetchMode {
        case .waitForAllDone:
            prefetchService.prefetchAllAssets { result in
                handleAssetsLoadedResultWith(identifier: identifier, result: result, finishedCallback: finishedCallback)
            }
        case .waitForFirstDone:
            prefetchService.startLazyPrefetching()
            prefetchService.onScreenReady(screenId: screenGraph.launchScreenId) { result in
                handleAssetsLoadedResultWith(identifier: identifier, result: result, finishedCallback: finishedCallback)
            }
        case .waitForScreenToLoad(let timeout):
            prefetchService.startLazyPrefetching()
            prefetchService.onScreenReady(screenId: screenGraph.launchScreenId, timeout: timeout) { result in
                handleAssetsLoadedResultWith(identifier: identifier, result: result, finishedCallback: finishedCallback)
            }
        }
    }
    
    static func handleAssetsLoadedResultWith(identifier: String,
                                             result: AssetsPrefetchResult,
                                             finishedCallback: @escaping OnboardingPreparationFinishCallback) {
        switch result {
        case .success:
            finishedCallback(.success(Void()))
            notifyOnboardingWaitersAndClearWith(identifier: identifier, state: .ready)
        case .failure(let error):
            finishedCallback(.failure(.init(error: error)))
            notifyOnboardingWaitersAndClearWith(identifier: identifier, state: .failed(error))
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
                switch state {
                case .ready:
                    waiter(.success(Void()))
                case .failed(let error):
                    waiter(.failure(.init(error: error)))
                default:
                    return
                }
            }
            onboardingData.waiters.removeAll()
        }
    }
    
    static func startOnboardingWith(identifier: String,
                                    finishedCallback: @escaping OnboardingFinishResult) {
        guard let onboardingData = getPreparedOnboardingData(identifier: identifier),
            let screenGraph = onboardingData.screenGraph else {
            finishedCallback(.failure(.init(error: OnboardingPreparationError.requestedOnboardingIsNotReady)))
            return
        }
        
        let runConfiguration = OnboardingService.RunConfiguration(screenGraph: screenGraph,
                                                                  appearance: OnboardingService.shared.appearance ?? .default,
                                                                  launchWithAnimation: true)
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
