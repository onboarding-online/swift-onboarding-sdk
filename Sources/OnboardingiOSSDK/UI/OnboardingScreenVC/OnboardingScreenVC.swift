//
//  OnboardingScreenVC.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 09.03.2023.
//

import UIKit
import ScreensGraph

class OnboardingScreenVC: BaseOnboardingScreen, OnboardingScreenProtocol {
    
    static func instantiateWith(screen: Screen,
                                videoPreparationService: VideoPreparationService,
                                delegate: OnboardingScreenDelegate) -> OnboardingScreenVC {
        let vc = OnboardingScreenVC.nibInstance()
        vc.screen = screen
        vc.videoPreparationService = videoPreparationService
        vc.delegate = delegate
        return vc
    }
    
    @IBOutlet private weak var backgroundContainerView: UIView!

    @IBOutlet private weak var mainChildContainerView: UIView!

    @IBOutlet private weak var childContainerView: UIView!
    @IBOutlet private weak var headerContainerView: UIView!
    @IBOutlet private weak var footerContainerView: UIView!
    
    @IBOutlet private var footerContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var footerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var progressBarTopConstraint: NSLayoutConstraint!


    
    weak var delegate: OnboardingScreenDelegate?
    var screen: Screen!
    var videoPreparationService: VideoPreparationService!
    var value: Any?
    var permissionValue: Bool?
    var transitionKind: ScreenTransitionKind?

    private weak var timer: Timer?
    
    private var childScreen: BaseOnboardingViewController?
    private var screenData: BaseScreenProtocol?
    private var permissionAction: Action?

    private var didAskForPermissions = false
    var isTimerFinished = false

    
    private var footerController: FooterVCProtocol? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMainUIBlocks()
        setupChildScreensConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setFooterStateBasedOnUserInputValue()

        OnboardingService.shared.eventRegistered(event: .screenDidAppear, params: [.screenID: screen.id, .screenName: screen.name])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkPermission()
        setupTimer()
    }
    
}

extension OnboardingScreenVC: OnboardingChildScreenDelegate {
    
    func onboardingChildScreenUpdate(value: Any?, description : String?, logAnalytics: Bool = true) {
        self.value = value
        
        setFooterStateBasedOnUserInputValue()
        
        var params: AnalyticsEventParameters = [.screenID : screen.id, .screenName : screen.name]
        
        if let description = description {
            params[.buttonTitle] = description
        }
        
        if let value = value {
            params[.userInputValue] = value
            if logAnalytics {
                OnboardingService.shared.eventRegistered(event: .userUpdatedValue, params: params )
            }
        }
    }
    
    func onboardingChildScreenPerform(action: Action) {
        self.finishWith(action: action)
    }
}

// MARK: - Private methods
private extension OnboardingScreenVC {
    
    func setupChildScreensConstraints() {
        if screen.containerToTop() {
            mainChildContainerView.sendSubviewToBack(childContainerView)
            headerContainerView.bringSubviewToFront(mainChildContainerView)
            NSLayoutConstraint.activate([
                childContainerView.topAnchor.constraint(equalTo: backgroundContainerView.topAnchor, constant: 0),
                childContainerView.bottomAnchor.constraint(equalTo: footerContainerView.topAnchor, constant: 0),
                childContainerView.leadingAnchor.constraint(equalTo: backgroundContainerView.leadingAnchor, constant: 0),
                childContainerView.trailingAnchor.constraint(equalTo: backgroundContainerView.trailingAnchor, constant: 0)
            ])
        } else if screen.containerTillLeftRightParentView() {
            NSLayoutConstraint.activate([
                childContainerView.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor, constant: 0),
                childContainerView.bottomAnchor.constraint(equalTo: footerContainerView.topAnchor, constant: 0),
                childContainerView.leadingAnchor.constraint(equalTo: backgroundContainerView.leadingAnchor, constant: 0),
                childContainerView.trailingAnchor.constraint(equalTo: backgroundContainerView.trailingAnchor, constant: 0)
            ])
        }
    }
    
    func setFooterStateBasedOnUserInputValue() {
        if let any = self.value as? [Int] {
            footerController?.updateFooterDependsOn(userValueIsEmpty: any.isEmpty)
        } else {
            if let any = self.value as? String {
                footerController?.updateFooterDependsOn(userValueIsEmpty: any.isEmpty)
            }
        }
    }
    
    func setupMainUIBlocks() {
        footerBottomConstraint = footerContainerBottomConstraint
        backgroundView = backgroundContainerView

        setupScreenConfigAndScreenBodyContainer()
        setupBackground()

        setupNavBar()
        setupFooter()
        
    }
    
    func onboardingViewControllerFor(screen: Screen) -> BaseChildScreenGraphViewController? {
        if let baseScreenStruct =  ChildControllerFabrika.viewControllerFor(screen: screen, videoPreparationService: videoPreparationService) {
            self.permissionAction = baseScreenStruct.permissionAction
            self.screenData = baseScreenStruct.baseScreen
            
            let controller = baseScreenStruct.childController
            controller.animationEnabled = baseScreenStruct.baseScreen.animationEnabled

            controller.delegate = self
            return controller
        }
        
        return nil
    }
    
    func setupScreenConfigAndScreenBodyContainer() {
        if let childScreen = onboardingViewControllerFor(screen: screen) {
            addChildViewController(childScreen, andEmbedToView: childScreen.isEmbedded ? childContainerView : view)
            self.childScreen = childScreen
        }
    }
    
}

private extension OnboardingScreenVC {
    
    func setupNavBar() {
        if let navigation = self.screenData?.navigationBar, navigation.isNavigationBarAvailable() {
            let headerController = OnboardingHeaderVC.instantiate(navigationBar: navigation)
            addChildViewController(headerController, andEmbedToView: headerContainerView)
            
            headerController.rightBarButtonAction = {[weak self](action) in
                if let screen = self?.screen {
                    self?.isTimerFinished = true
                    OnboardingService.shared.eventRegistered(event: .rightNavbarButtonPressed, params: [.screenID : screen.id, .screenName : screen.name])
                }

                self?.finishWith(action: action)
            }
            
            headerController.backButtonAction = {[weak self]() in
                self?.view.endEditing(true)
                if let screen = self?.screen {
                    OnboardingService.shared.eventRegistered(event: .leftNavbarButtonPressed, params: [.screenID : screen.id, .screenName : screen.name])
                }
                
                DispatchQueue.main.async {
                    guard let strongSelf = self else { return }
                    
                    switch strongSelf.transitionKind {
                    case ._default, .none:
                        strongSelf.navigationController?.popViewController(animated: true)
                    case .modal:
                        strongSelf.dismiss(animated: true)
                    }
                }
            }
        } else {
            hideNavigationBar()
        }
    }
    
    func hideNavigationBar() {
        progressBarTopConstraint.constant = headerContainerView.bounds.height * -1
        headerContainerView.isHidden = true
        headerContainerView.isMultipleTouchEnabled = false
    }

}


fileprivate extension OnboardingScreenVC {
    
    func setupFooter() {
        if let footer = screenData?.footer, footer.isFooterAvailable()  {
            
            if (footer.kind ?? BasicFooterKind.vertical) == BasicFooterKind.horizontal {
                let footerController = OnboardingFooterHorizontalVC.instantiate(footer: footer)
                addChildViewController(footerController, andEmbedToView: footerContainerView)
                footerController.animationEnabled = screenData?.animationEnabled ?? true

                footerHeightConstraint.constant = footerController.calculateFooterHeight()
                self.footerContainerBottomConstraint = footerController.bottomFooterConstrain
                self.footerHeightConstraint = footerController.topFooterConstrain
                
                footerController.firstButtonAction = {[weak self](action) in
                    if let screen = self?.screen {
                        OnboardingService.shared.eventRegistered(event: .firstFooterButtonPressed, params: [.screenID : screen.id, .screenName : screen.name])
                    }
                    
                    self?.finishWith(action: action)
                    self?.isTimerFinished = true
                }
                
                footerController.secondButtonAction = {[weak self](action) in
                    if let screen = self?.screen {
                        OnboardingService.shared.eventRegistered(event: .secondFooterButtonPressed, params: [.screenID : screen.id, .screenName : screen.name])
                    }
                    
                    self?.finishWith(action: action)
                    self?.isTimerFinished = true
                }
                self.footerController = footerController
            } else {
                let footerController = OnboardingFooterVC.instantiate(footer: footer)
                addChildViewController(footerController, andEmbedToView: footerContainerView)
                footerController.animationEnabled = screenData?.animationEnabled ?? true

                footerHeightConstraint.constant = footerController.calculateFooterHeight()
                self.footerContainerBottomConstraint = footerController.bottomFooterConstrain
                self.footerHeightConstraint = footerController.topFooterConstrain
                
                footerController.firstButtonAction = {[weak self](action) in
                    if let screen = self?.screen {
                        OnboardingService.shared.eventRegistered(event: .firstFooterButtonPressed, params: [.screenID : screen.id, .screenName : screen.name])
                    }
                    
                    self?.finishWith(action: action)
                    self?.isTimerFinished = true
                }
                
                footerController.secondButtonAction = {[weak self](action) in
                    if let screen = self?.screen {
                        OnboardingService.shared.eventRegistered(event: .secondFooterButtonPressed, params: [.screenID : screen.id, .screenName : screen.name])
                    }
                    
                    self?.finishWith(action: action)
                    self?.isTimerFinished = true
                }
                self.footerController = footerController
            }
            
          
        } else {
            hideFooter()
        }
    }
    
    func hideFooter() {
        footerContainerBottomConstraint.constant = footerContainerView.bounds.height * -1
        footerContainerView.isHidden = true
        footerContainerView.isMultipleTouchEnabled = false
    }
    
}

fileprivate extension OnboardingScreenVC {
    var useLocalAssetsIfAvailable: Bool { screenData?.useLocalAssetsIfAvailable ?? true }
    
    func setupBackground() {
        if let background = self.screenData?.styles.background {
            switch background.styles {
            case .typeBackgroundStyleColor(let value):
                backgroundContainerView.backgroundColor = value.color.hexStringToColor
            case .typeBackgroundStyleImage(let value):
                backgroundContainerView.backgroundColor = .clear
                updateBackground(image: value.image,
                                 useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
            case .typeBackgroundStyleVideo:
                setupBackgroundFor(screenId: screen.id,
                                   using: videoPreparationService)
            }
        }
    }

}


fileprivate extension OnboardingScreenVC {
    
    func checkPermission() {
        if !didAskForPermissions, let requestPermission = self.screenData?.permission {
            if let permissionRequest = OnboardingService.shared.permissionRequestCallback {
                didAskForPermissions = true
                
                permissionRequest(screen, requestPermission.type)
                OnboardingService.shared.eventRegistered(event: .permissionRequested, params: [.screenID : screen.id, .screenName : screen.name, .permissionType : requestPermission.type.rawValue])
            }
        }
    }
}


fileprivate extension OnboardingScreenVC {
    
    func setupTimer() {
        if let timerDuration = screenData?.timer?.duration.doubleValue {
//            if timerDuration == 999.0 {
//                timerDuration = 9.2
//            }
            
            timer = Timer.scheduledTimer(timeInterval: timerDuration, target: self, selector: #selector(self.showNextScreen), userInfo: nil, repeats: false)
        }
    }
    
    @objc func showNextScreen() {
        if timer?.isValid ?? false {
            timer?.invalidate()
        }
        
        if !isTimerFinished {
            OnboardingService.shared.eventRegistered(event: .switchedToNewScreenOnTimer, params: [.screenID : screen.id, .screenName : screen.name])

            finishWith(action: screenData?.timer?.action)
        }
        
    }
}


private extension OnboardingScreenVC {
    
    func finishWith(action: Action?) {
        DispatchQueue.main.async {[weak self] in
            guard let strongSelf = self, let action = action  else { return }
            self?.view.endEditing(true)

            strongSelf.delegate?.onboardingScreen(strongSelf, didFinishWithScreenData: action)
        }
    }
    
}
