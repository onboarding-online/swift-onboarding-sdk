//
//  OnboardingScreenVC.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 09.03.2023.
//

import UIKit
import ScreensGraph

class OnboardingHeaderVC: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var dashesProgressView: DashesProgressView!
    @IBOutlet weak var dashesTitle: UILabel!

    @IBOutlet weak var parentProgressView: UIView!


    @IBOutlet var dashProgressHeightConstraint: NSLayoutConstraint!
    
    
    @IBOutlet var dashProgressBottomConstraint: NSLayoutConstraint!
    @IBOutlet var dashProgressVerticalCenterConstraint: NSLayoutConstraint!

    @IBOutlet var backButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet var backButtonHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var backButtonContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet var backButtonContainerHeightConstraint: NSLayoutConstraint!

    public var rightBarButtonAction: ((Action) -> ())? = nil
    public var backButtonAction: (() -> ())? = nil
    
    var navigationBar : NavigationBar!
    
    static func instantiate(navigationBar: NavigationBar) -> OnboardingHeaderVC {
        let headerVC = OnboardingHeaderVC.nibInstance()
        headerVC.navigationBar = navigationBar
        return headerVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupNavBar()

    }
    
}

private extension OnboardingHeaderVC {
    
    func setupSkipButton() {
        if let skip  = navigationBar.skip {
            skipButton.apply(button: skip)
        } else {
            skipButton.isHidden = true
        }
    }
    
    func setupBackButton() {
        if let back  = navigationBar.back {
            backButton.apply(button: back, isBackButton: true)
            
            if back.isDefaultBackIcon() {
                backButtonWidthConstraint.constant = 16.0
                backButtonHeightConstraint.constant = 24.0
                
                if let width =  back.styles.width, let height =  back.styles.width {
                    backButtonWidthConstraint.constant = width
                    backButtonHeightConstraint.constant = height
                }
            }
        } else {
            backButton.isHidden = true
        }
    }
    
    func setupProgress() {
        dashesProgressView.isHidden = true
        dashesTitle.isHidden = true
        
        if let progress  = navigationBar.pageIndicator, let progressView = progressView {
            let value = (progress.value / 100.0).floatValue

            if let navigationBarLind = navigationBar.pageIndicatorKind {
                switch navigationBarLind {
                case .dashesWithTitle:
                    if let config = DashesProgressView.Configuration.initWith(navigationBar: navigationBar) {
                        dashesProgressView.isHidden = false
                        dashesTitle.isHidden = false
                        progressView.isHidden = true
                        parentProgressView.layoutIfNeeded()
                        
                        dashProgressVerticalCenterConstraint.isActive = false
                        dashProgressBottomConstraint.isActive = true
                        dashesTitle.isHidden = false
                        
                        dashProgressHeightConstraint.constant = navigationBar.dashesPageIndicator?.styles.dashHeight ?? 2
                        dashesProgressView.setWith(configuration: config)
                        dashesProgressView.setProgress(value.doubleValue)
                        dashesTitle.apply(text: navigationBar.dashesPageIndicator?.title)
                    }
                case .dashes:
                    if let config = DashesProgressView.Configuration.initWith(navigationBar: navigationBar) {
                        dashesProgressView.isHidden = false
                        dashesTitle.isHidden = false
                        progressView.isHidden = true
                        parentProgressView.layoutIfNeeded()
                        dashProgressVerticalCenterConstraint.isActive = true
                        dashProgressBottomConstraint.isActive = false
                        dashesTitle.isHidden = true
                        dashProgressHeightConstraint.constant = navigationBar.dashesPageIndicator?.styles.dashHeight ?? 2
                        dashesProgressView.setWith(configuration: config)
                        dashesProgressView.setProgress(value.doubleValue)
                    }
                default:
                    
                    
                    break
                }
            }
            
            let filledColor = progress.styles.color?.hexStringToColor ?? .clear
            let notFilledColor = progress.styles.trackColor?.hexStringToColor ?? .lightGray
            progressView.tintColor = filledColor
            progressView.trackTintColor = notFilledColor
            progressView.setProgress(value, animated: false)
        } else {
            progressView.isHidden = true
        }
    }
    
    func setupNavBar() {
        setupSkipButton()
        setupProgress()
        setupBackButton()
    }
    
    @IBAction func skipButtonAction(_ sender: Any) {
        if let action  = navigationBar.skip?.action, let callBack =  rightBarButtonAction {
            callBack(action)
        }
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        if let callBack =  backButtonAction {
            callBack()
        }
    }
    
}


