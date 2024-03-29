//
//  OnboardingService.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 19.02.2023.
//

import UIKit
import ScreensGraph

public typealias OnboardingFinishResult = GenericResultCallback<OnboardingData>

public final class OnboardingService {
    
    public static let shared = OnboardingService()

    private let windowManager = OnboardingWindowManager.shared
    public var customFlow: CustomScreenCallback? = nil
    
    public var permissionRequestCallback: PermissionRequestCallback? = nil
    
    public var userEventListener: ((AnalyticsEvent, [String: Any]?) -> ())? = nil
    public var systemEventListener: ((AnalyticsEvent, [String: Any]?) -> ())? = nil

    public var customLoadingViewController: UIViewController?
    public var assetsPrefetchMode: AssetsPrefetchMode = .waitForScreenToLoad(timeout: 0.5)

    public var screenGraph: ScreensGraph?

    private var environment: OnboardingEnvironment = .prod
    private var initialRootViewController: UIViewController?
    private var navigationController: OnboardingNavigationController?
    public  var appearance: AppearanceStyle?
    private var launchWithAnimation: Bool = false
    private var prefetchService: AssetsPrefetchService?
    private var videoPreparationService: VideoPreparationService?
    private var currentLoadingViewController: UIViewController?

    private var onboardingUserData: OnboardingData = [:]
    private var onboardingFinishedCallback: OnboardingFinishResult?
    
    private init() { 
        BackgroundTasksService.shared.startTrackAppState()
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
}

// MARK: - Open methods
extension OnboardingService {
    
    public func startOnboarding(configuration: RunConfiguration,
                                finishedCallback: @escaping  GenericResultCallback<OnboardingData>) {
        startOnboarding(configuration: configuration,
                        prefetchService: nil,
                        finishedCallback: finishedCallback)
    }
    
    func startOnboarding(configuration: RunConfiguration,
                         prefetchService: AssetsPrefetchService?,
                         finishedCallback: @escaping  GenericResultCallback<OnboardingData>) {
        let screenGraph = configuration.screenGraph
        guard screenGraph.screens[screenGraph.launchScreenId] != nil else { return }
        
        self.onboardingFinishedCallback = finishedCallback
        self.screenGraph = screenGraph
        videoPreparationService = VideoPreparationService(screenGraph: screenGraph)
        self.appearance = configuration.appearance
        self.launchWithAnimation = configuration.launchWithAnimation
        
        if let prefetchService {
            self.prefetchService = prefetchService
            showOnboardingFlowViewController(nextScreenId: screenGraph.launchScreenId, transitionKind: ._default)
        } else {
            let prefetchService = AssetsPrefetchService(screenGraph: screenGraph)
            self.prefetchService = prefetchService
            
            switch assetsPrefetchMode {
            case .waitForAllDone:
                if !screenGraph.launchScreenId.isEmpty {
                    showLoadingAssetsScreen()
                }
                prefetchService.prefetchAllAssets { [weak self] _ in
                    self?.showOnboardingFlowViewControllerWhenReady(nextScreenId: screenGraph.launchScreenId)
                }
            case .waitForFirstDone:
                prefetchService.startLazyPrefetching()
                showOnboardingFlowViewControllerWhenReady(nextScreenId: screenGraph.launchScreenId)
            case .waitForScreenToLoad:
                prefetchService.startLazyPrefetching()
                showOnboardingFlowViewControllerWhenReady(nextScreenId: screenGraph.launchScreenId)
            }
        }
    }
    
    public func customFlowFinished(customScreen: Screen, userInputValue: CustomScreenUserInputValue?) {
        DispatchQueue.main.async { [weak self] in
            if let customScreenData = customScreen.customScreenValue()  {
                let param = userInputValue ?? [:]
                OnboardingService.shared.eventRegistered(event: .customScreenDisappeared, params: [.customScreenUserInputValue : param, .screenID: customScreen.id, .screenName: customScreen.name])
                self?.finished(screen: customScreen, userInputValue: userInputValue, didFinishWith: customScreenData.callback.action)
            } else {
                OnboardingService.shared.eventRegistered(event: .customScreenDisappeared, params: [.customScreenUserInputValue : ["":""], .screenID: customScreen.id, .screenName: customScreen.name])
            }
        }
    }
    
    func showLoadingAssetsScreen(appearance: AppearanceStyle,
                                 launchWithAnimation: Bool) {
        self.appearance = appearance
        self.launchWithAnimation = launchWithAnimation
        showLoadingAssetsScreen()
    }

}

// MARK: - OnboardingScreenDelegate
extension OnboardingService: OnboardingScreenDelegate {
    
    func onboardingScreen(_ onboardingScreen: OnboardingScreenProtocol, updatedValue: Any) {
        eventRegistered(event: .userUpdatedValue, params: [.screenID : onboardingScreen.screen.id, .screenName : onboardingScreen.screen.name, .userInputValue: updatedValue])
    }
    
    func onboardingScreen(_ onboardingScreen: OnboardingScreenProtocol,
                          didFinishWithScreenData screenData: ScreenData) {
        finished(screen: onboardingScreen.screen, userInputValue: onboardingScreen.value, didFinishWith: screenData)
    }
    
    private func finished(screen: Screen, userInputValue: Any?, didFinishWith action: ScreenData) {
        if let value = userInputValue {
            onboardingUserData[screen.id] = value
        }
        let edge = findEdgeFor(action: action, screenGraph: self.screenGraph, onboardingUserData: self.onboardingUserData)
        let screenId =  edge?.nextScreenId ?? action?.edges.first?.nextScreenId
        let transitionKind = edge?.transitionKind ?? ._default
        
        eventRegistered(event: .screenDisappeared, params: [.screenID : screen.id, .screenName : screen.name, .nextScreenId: screenId ?? "",  .userInputValue : userInputValue ?? ""])
        
        showOnboardingFlowViewController(nextScreenId: screenId,
                                         transitionKind: transitionKind)
    }

    func onboardingScreen(_ onboardingScreen: OnboardingScreenProtocol,
                          didRegisterUIEvent event: String,
                          withParameters parameters: OnboardingData) {
    }
}

extension OnboardingService {
    
    public func eventRegistered(event: AnalyticsEvent?, params: AnalyticsEventParameters?) {
        DispatchQueue.main.async { [weak self] in
            if let event = event, let eventListener = self?.userEventListener {
                var stringKeyDict = [String: Any]()
                if let params = params {
                    for (key,value) in params {
                        stringKeyDict[key.rawValue] = value
                    }
                }
                eventListener(event, stringKeyDict)
            }
        }
    }
    
    public func systemEventRegistered(event: AnalyticsEvent?, params: AnalyticsEventParameters?) {
        DispatchQueue.main.async { [weak self] in
            if let event = event, let debugEventListener = self?.systemEventListener {
                var stringKeyDict = [String: Any]()
                if let params = params {
                    for (key,value) in params {
                        stringKeyDict[key.rawValue] = value
                    }
                }
                debugEventListener(event, stringKeyDict)
            }
        }
    }
    
}

private extension OnboardingService {
    
    func findEdgeFor(action : Action?, screenGraph: ScreensGraph?, onboardingUserData: OnboardingData) -> ConditionedAction? {
        if let edges = action?.edges, let screenGraph = screenGraph  {
            //  check conditioned edges, if screen value is empty we could not compare it with any condition
            for edge in  edges {
                if !edge.rule.isEmpty {
                    if  edge.checkRuleFor(screenGraph: screenGraph, screenValues: onboardingUserData) {
                        systemEventRegistered(event: .nextScreenEdgeWithCondition, params: [.edge : edge])

                        return edge
                    }
                }
            }
            
            //  check unconditioned edges
            for edge in  edges {
                if edge.rule.isEmpty {
                    systemEventRegistered(event: .nextScreenEdgeWithoutCondition, params: [.edge : edge])
                    return edge
                }
            }
            //  if we didn't find right condition return first one
            let randomEdge = edges.first
            if randomEdge != nil {
                systemEventRegistered(event: .nextScreenEdgeForWrongConditions, params: [.edge : randomEdge ?? ""])
            }

            return randomEdge
        }
        
        return nil
    }
}

// MARK: - OnboardingNavigationControllerDelegate
extension OnboardingService: OnboardingNavigationControllerDelegate { }

// MARK: - Private methods
private extension OnboardingService {
    var isRunningOnboarding: Bool { screenGraph != nil }
    
    @objc func willEnterForeground() {
        // Fix inactive window
        if isRunningOnboarding,
           windowManager.getActiveWindow() == nil {
            switch appearance {
            case .default, .presentIn:
                windowManager.getWindows().first?.makeKeyAndVisible()
            case .window(let window):
                window.makeKeyAndVisible()
            case .none:
                return
            }
        }
    }
    
    func showOnboardingFlowViewControllerWhenReady(nextScreenId: String?,
                                                   transitionKind: ScreenTransitionKind = ._default) {
        switch assetsPrefetchMode {
        case .waitForAllDone:
            showOnboardingFlowViewController(nextScreenId: nextScreenId,
                                             transitionKind: transitionKind)
        case .waitForFirstDone:
            if let nextScreenId = nextScreenId,
               nextScreenId == screenGraph?.launchScreenId {
                waitForAssetsLoadingAndShowOnboardingScreenFor(screenId: nextScreenId,
                                                               timeout: nil,
                                                               transitionKind: transitionKind)
            } else {
                showOnboardingFlowViewController(nextScreenId: nextScreenId,
                                                 transitionKind: transitionKind)
            }
        case .waitForScreenToLoad(let timeout):
            if let nextScreenId = nextScreenId {
                waitForAssetsLoadingAndShowOnboardingScreenFor(screenId: nextScreenId,
                                                               timeout: timeout,
                                                               transitionKind: transitionKind)
            } else {
                showOnboardingFlowViewController(nextScreenId: nextScreenId,
                                                 transitionKind: transitionKind)
            }
        }
    }
    
    func showLoadingAssetsScreen() {
        if navigationController == nil,
           currentLoadingViewController == nil {
            let currentLoadingViewController = customLoadingViewController ?? ScreenLoadingAssetsVC.nibInstance()
            self.currentLoadingViewController = currentLoadingViewController
            let loadingAssetsVC = currentLoadingViewController
            setInitialOnboardingController(loadingAssetsVC)
        }
    }
    
    func waitForAssetsLoadingAndShowOnboardingScreenFor(screenId: String,
                                                        timeout: TimeInterval?,
                                                        transitionKind: ScreenTransitionKind) {
        if screenId == screenGraph?.launchScreenId {
            showLoadingAssetsScreen()
        }
        prefetchService?.onScreenReady(screenId: screenId,
                                       timeout: timeout) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.showOnboardingFlowViewController(nextScreenId: screenId, transitionKind: transitionKind)
            }
        }
    }
    
    func showOnboardingFlowViewController(nextScreenId: String?,
                                          transitionKind: ScreenTransitionKind) {
        guard let screenGraph = self.screenGraph,
            let videoPreparationService = self.videoPreparationService else { return }
        
        if let nextScreenId = nextScreenId,
           let screen = screenGraph.screens[nextScreenId] {
            if screen.isCustomScreen() {
                if !tryToStartCustomFlow(screen: screen) {
                    finishOnboarding()
                }
            } else {
                let controller = onboardingViewControllerFor(screen: screen,
                                                             videoPreparationService: videoPreparationService)
                controller.transitionKind = transitionKind
                
                if nextScreenId == screenGraph.launchScreenId {
                    setInitialOnboardingController(controller)
                } else {
                    showNextOnboardingController(controller, transitionKind: transitionKind)
                }
            }
        } else {
            finishOnboarding()
        }
    }
    
    func onboardingViewControllerFor(screen: Screen,
                                     videoPreparationService: VideoPreparationService) -> OnboardingScreenVC {
        let vc = OnboardingScreenVC.instantiateWith(screen: screen,
                                                    videoPreparationService: videoPreparationService,
                                                    delegate: self)
        return vc
    }
    
    func setInitialOnboardingController(_ controller: UIViewController) {
        guard let appearance = self.appearance else { return }
        
        
        func setInitialIn(window: UIWindow) {
            let navigationController = wrapViewControllerInNavigation(controller)
            self.navigationController = navigationController
            
            if !(window.rootViewController is OnboardingNavigationController) {
                initialRootViewController = window.rootViewController
            }
            
            if launchWithAnimation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.windowManager.setNewRootViewController(navigationController, in: window, animated: true)
                }
            } else {
                windowManager.setNewRootViewController(navigationController, in: window, animated: false)
            }
        }
        
        switch appearance {
        case .default:
            guard let window = windowManager.getCurrentWindow() else { return }
            
            setInitialIn(window: window)
        case .window(let window):
            setInitialIn(window: window)
        case .presentIn(let viewController):
            if let existingNavigation = self.navigationController {
                existingNavigation.viewControllers = [controller]
            } else {
                let navigationController = wrapViewControllerInNavigation(controller)
                self.navigationController = navigationController
                
                navigationController.modalPresentationStyle = .fullScreen
                navigationController.modalTransitionStyle = .crossDissolve
                viewController.present(navigationController, animated: true)
            }
        }
    }
    
    func showNextOnboardingController(_ controller: UIViewController, transitionKind: ScreenTransitionKind) {
        switch transitionKind {
        case ._default:
            getTopNavigationController()?.pushViewController(controller, animated: true)
        case .modal:
            let nav = wrapViewControllerInNavigation(controller)
            getTopNavigationController()?.present(nav, animated: true)
        }
    }
    
    func getTopNavigationController() -> UINavigationController? {
        guard var navigationController = self.navigationController else { return nil }
        
        while true {
            if let presentedNavigationController = navigationController.presentedViewController as? OnboardingNavigationController {
                navigationController = presentedNavigationController
            } else {
                break
            }
        }
        
        return navigationController
    }
    
    func wrapViewControllerInNavigation(_ viewController: UIViewController) -> OnboardingNavigationController {
        OnboardingNavigationController(rootViewController: viewController)
    }
    
    func finishOnboarding() {
        eventRegistered(event: .onboardingFinished, params: [.userInputValues: onboardingUserData])
        
        let result = GenericResult.success(onboardingUserData)
        defer { onboardingFinishedCallback?(result) }
        
        guard let appearance = self.appearance else { return }

        func finishIn(window: UIWindow) {
            guard let initialRootViewController = self.initialRootViewController else { return }
            windowManager.setNewRootViewController(initialRootViewController, in: window)
        }
        
        switch appearance {
        case .default:
            guard let window = windowManager.getCurrentWindow() else { return }
            finishIn(window: window)
        case .window(let window):
            finishIn(window: window)
        case .presentIn:
            if let presentingViewController = navigationController?.presentingViewController {
                presentingViewController.dismiss(animated: true)
            } else {
                navigationController?.dismiss(animated: true)
            }
        }
        
        self.initialRootViewController = nil
        self.screenGraph = nil
        self.navigationController = nil
        self.appearance = nil
        self.prefetchService = nil
        self.onboardingUserData = [:]
        self.customLoadingViewController = nil
        self.currentLoadingViewController = nil
        self.videoPreparationService = nil
    }
}

// MARK: -  Custom flow
extension OnboardingService {
    
    struct CustomFlowDescription {
        let screen: Screen
        let lastRootViewController: UIViewController
    }
    
    func isScreenCustom(_ screen: Screen) -> Bool {
        screen.screenType ==  ScreenType.customScreen
    }
    
    func tryToStartCustomFlow(screen: Screen) -> Bool {
        guard let flow = self.customFlow,
              let navigationController = self.getTopNavigationController(),
              let screenData = screen.customScreenValue() else {
             OnboardingService.shared.eventRegistered(event: .customScreenNotImplementedInCodeOnboardingFinished, params: [.screenName : screen.name, .screenID : screen.id])

            return false
        }
        
        OnboardingService.shared.eventRegistered(event: .customScreenRequested, params: [.screenName : screen.name, .screenID : screen.id, .customScreenLabelsValue : screenData.values])

        onboardingUserData[screen.id] = screenData.values
        
        let customFlowContainerVC = UIViewController()
        let customFlowNavigationController = UINavigationController()
        UIView.performWithoutAnimation {
            customFlowContainerVC.addChildViewController(customFlowNavigationController,
                                                         andEmbedToView: customFlowContainerVC.view)
        }

        flow(screen, customFlowNavigationController)
        navigationController.pushViewController(customFlowContainerVC, animated: true)
        return true
    }
}


// MARK: - Open methods
public extension OnboardingService {
    
    enum AppearanceStyle {
        case `default`
        case window(_ window: UIWindow)
        case presentIn(_ viewController: UIViewController)
    }
    
    enum AssetsPrefetchMode {
        case waitForAllDone
        case waitForFirstDone
        case waitForScreenToLoad(timeout: TimeInterval)
    }

    struct LoadConfiguration {
        public let projectId: String
        public let options: Options
        public var env: OnboardingEnvironment = .prod
        public var appearance: AppearanceStyle = .default
        public var launchWithAnimation: Bool
        
        public init(projectId: String,
                    options: Options,
                    env: OnboardingEnvironment = .prod,
                    appearance: AppearanceStyle = .default,
                    launchWithAnimation: Bool = false) {
            self.projectId = projectId
            self.options = options
            self.env = env
            self.appearance = appearance
            self.launchWithAnimation = launchWithAnimation
        }
        
        public enum Options {
            case waitForRemote
            case useLocalAfterTimeout(localPath: URL, timeout: TimeInterval)
        }
    }
    
    struct RunConfiguration {
        public let screenGraph: ScreensGraph
        public var appearance: AppearanceStyle = .default
        public var launchWithAnimation: Bool

        public init(screenGraph: ScreensGraph,
                    appearance: AppearanceStyle = .default,
                    launchWithAnimation: Bool = false) {
            self.screenGraph = screenGraph
            self.appearance = appearance
            self.launchWithAnimation = launchWithAnimation
        }
    }
}
 
public class GenericError: Error {
    static public let NoResultError = GenericError(errorCode: -1, localizedDescription: "Something went wrong")
    
    var errorCode: Int
    var localizedDescription: String
    
    init(errorCode: Int, localizedDescription: String) {
        self.errorCode = errorCode
        self.localizedDescription = localizedDescription
    }
    
    convenience init(error: Error) {
        self.init(errorCode: -1, localizedDescription: error.localizedDescription)
    }
}
