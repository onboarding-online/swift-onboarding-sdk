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
    
    static func donloadOnboardingAndAssetsFor(projectId: String,
                                      localJSONFileName: String,
                                      env: OnboardingEnvironment = .prod,
                                      finishedCallback: @escaping OnboardingPreparationFinishCallback) {
        OnboardingLoadingService.loadScreenGraphFor(projectId: projectId,
                                                    env: env) { result in
            switch result {
            case .success(let screenGraph):
                let identifier = onboardingIdentifierFor(projectId: projectId, env: env)
                loadAssetsFor(screenGraph: screenGraph,
                              identifier: identifier,
                              finishedCallback: finishedCallback)
            case .failure(_):
                OnboardingPreparationService.prepareFullOnboarding(localJSONFileName: localJSONFileName, finishedCallback: finishedCallback)
            }
        }
    }
    
    static func prepareFullOnboarding(localJSONFileName: String,
                                      finishedCallback: @escaping OnboardingPreparationFinishCallback) {
        do {
            let localScreenGraph = try OnboardingLoadingService.getOnboardingFromLocalJsonName(localJSONFileName)
            loadAssetsFor(screenGraph: localScreenGraph,
                          identifier: localJSONFileName,
                          finishedCallback: finishedCallback)
        } catch {
            finishedCallback(.failure(.init(error: error)))
        }
    }
    
   
    
    static func prepareFullOnboarding(projectId: String,
                                      env: OnboardingEnvironment = .prod,
                                      finishedCallback: @escaping OnboardingPreparationFinishCallback) {
        OnboardingLoadingService.loadScreenGraphFor(projectId: projectId,
                                                    env: env) { result in
            switch result {
            case .success(let screenGraph):
                let identifier = onboardingIdentifierFor(projectId: projectId, env: env)
                loadAssetsFor(screenGraph: screenGraph,
                              identifier: identifier,
                              finishedCallback: finishedCallback)
            case .failure(let error):
                finishedCallback(.failure(error))
            }
        }
    }
    
    static func isOnboardingPrepared(localJSONFileName: String) -> Bool {
        isOnboardingPrepared(identifier: localJSONFileName)
    }
    
    static func isOnboardingPrepared(projectId: String,
                                     env: OnboardingEnvironment = .prod) -> Bool {
        let identifier = onboardingIdentifierFor(projectId: projectId, env: env)
        return isOnboardingPrepared(identifier: identifier)
    }
    
    static func startPreparedOnboarding(localJSONFileName: String,
                                        finishedCallback: @escaping OnboardingFinishResult) {
        startOnboardingWith(identifier: localJSONFileName, finishedCallback: finishedCallback)
    }
    
    static func startPreparedOnboarding(projectId: String,
                                        env: OnboardingEnvironment = .prod,
                                        finishedCallback: @escaping OnboardingFinishResult) {
        let identifier = onboardingIdentifierFor(projectId: projectId, env: env)
        startOnboardingWith(identifier: identifier, finishedCallback: finishedCallback)
    }
    
    static func startPreparedOnboarding(projectId: String,
                                        localJSONFileName: String,
                                        env: OnboardingEnvironment = .prod,
                                        finishedCallback: @escaping OnboardingFinishResult) {
        let identifier = onboardingIdentifierFor(projectId: projectId, env: env)
        startOnboardingWith(identifier: identifier, finishedCallback: finishedCallback)
    }
}

// MARK: - Private methods
private extension OnboardingPreparationService {
    
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
                              finishedCallback: @escaping OnboardingPreparationFinishCallback) {
        let prefetchService = AssetsPrefetchService(screenGraph: screenGraph)
        prefetchService.prefetchAllAssets { result in
            switch result {
            case .success:
                serialQueue.sync {
                    preparedOnboardingDataCache.append(.init(screenGraph: screenGraph, 
                                                             identifier: identifier,
                                                             prefetchService: prefetchService))
                }
                finishedCallback(.success(Void()))
            case .failure(let error):
                finishedCallback(.failure(.init(error: error)))
            }
        }
    }
    
    static func isOnboardingPrepared(identifier: String) -> Bool {
        serialQueue.sync {
            preparedOnboardingDataCache.first(where: { $0.identifier == identifier }) != nil
        }
    }
    
    static func getPreparedOnboardingData(identifier: String) -> PreparedOnboardingData? {
        preparedOnboardingDataCache.first(where: { $0.identifier == identifier })
    }
    
    static func startOnboardingWith(identifier: String,
                                    finishedCallback: @escaping OnboardingFinishResult) {
        guard let onboardingData = getPreparedOnboardingData(identifier: identifier) else {
            finishedCallback(.failure(.init(error: OnboardingPreparationError.requestedOnboardingIsNotReady)))
            return
        }
        
        let runConfiguration = OnboardingService.RunConfiguration(screenGraph: onboardingData.screenGraph,
                                                                  appearance: OnboardingService.shared.appearance ?? .default,
                                                                  launchWithAnimation: true)
        OnboardingService.shared.startOnboarding(configuration: runConfiguration,
                                                 prefetchService: onboardingData.prefetchService,
                                                 finishedCallback: finishedCallback)
    }
    
    struct PreparedOnboardingData {
        let screenGraph: ScreensGraph
        let identifier: String
        let prefetchService: AssetsPrefetchService
    }
    
    enum OnboardingPreparationError: Error {
        case requestedOnboardingIsNotReady
    }
}
