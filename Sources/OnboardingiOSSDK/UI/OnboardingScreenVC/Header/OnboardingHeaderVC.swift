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
            backButton.apply(button: back)
        } else {
            backButton.isHidden = true
        }
    }
    
    func setupProgress() {
        if let progres  = navigationBar.pageIndicator, let progressView = progressView {
            let value = (progres.value / 100.0).floatValue
            
            progressView.tintColor = progres.styles.color?.hexStringToColor ?? .clear
            progressView.trackTintColor = progres.styles.trackColor?.hexStringToColor ?? .clear

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


