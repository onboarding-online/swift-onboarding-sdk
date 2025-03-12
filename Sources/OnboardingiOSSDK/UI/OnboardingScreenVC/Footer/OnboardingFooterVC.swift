//
//  OnboardingScreenVC.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 09.03.2023.
//

import UIKit
import ScreensGraph

protocol FooterVCProtocol {
    func updateFooterDependsOn(userValueIsEmpty: Bool)
}

class OnboardingFooterVC: UIViewController, FooterVCProtocol {

    @IBOutlet weak var nextButton1: UIButton!
    @IBOutlet weak var containerButton1: UIView!

    @IBOutlet weak var nextButton2: UIButton!
    @IBOutlet weak var containerButton2: UIView!

    @IBOutlet weak var stackView: UIStackView!

    
    @IBOutlet var nextButton1Height: NSLayoutConstraint!
    @IBOutlet var nextButton2Height: NSLayoutConstraint!
    
    @IBOutlet var topFooterConstrain: NSLayoutConstraint!
    @IBOutlet var bottomFooterConstrain: NSLayoutConstraint!

    @IBOutlet var leadingNextButtonConstraint: NSLayoutConstraint!
    @IBOutlet var trailingNextButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet var centerNextButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet var secondButtonLeadingNextButtonConstraint: NSLayoutConstraint!
    @IBOutlet var secondButtonTrailingNextButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet var secondButtonCenterNextButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet var defaultFooterLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var defaultFooterTrailingConstraint: NSLayoutConstraint!
    
    public var firstButtonAction: ((Action) -> ())? = nil
    public var secondButtonAction: ((Action) -> ())? = nil
    
    var footer : Footer!
    var animationEnabled = false

    
    static func instantiate(footer: Footer) -> OnboardingFooterVC {
        let footerVC = OnboardingFooterVC.nibInstance()
        footerVC.footer = footer
        return footerVC
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNextButton()

        if animationEnabled {
            runInitialAnimation()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if OnboardingService.shared.disableDefaultFooterPaddings {
            defaultFooterLeadingConstraint.constant = 0
            defaultFooterTrailingConstraint.constant = 0
        }

        nextButton1.alpha =  nextButton1.isEnabled ? 1 : 0.5
        nextButton2.alpha =  nextButton2.isEnabled ? 1 : 0.5
    }

    
    func updateFooterDependsOn(userValueIsEmpty: Bool) {
        self.updateButtonDependsOn(userValueIsEmpty: userValueIsEmpty, button: footer.button1, uibutton: nextButton1)
        self.updateButtonDependsOn(userValueIsEmpty: userValueIsEmpty, button: footer.button2, uibutton: nextButton2)
    }
    
    
    func updateButtonDependsOn(userValueIsEmpty: Bool, button: Button?, uibutton: UIButton?) {
        if let buttonVisivility = button?.styles.visibility, let uibutton = uibutton {
            switch  buttonVisivility {
            case ._default:
                break
            case .disableduntilvalueentered:
                uibutton.isEnabled = !userValueIsEmpty
                uibutton.alpha =  uibutton.isEnabled ? 1 : 0.5
            case .hiddenuntilvalueentered:
                uibutton.isHidden = userValueIsEmpty

            }
        }
    }
    
    func calculateFooterHeight()  -> CGFloat {
        
        var footerHeight: CGFloat
        
        let topConstrain = 32.0
        let bottomConstrain = 32.0
        
        let betweenButtonsConstrain = stackView.spacing

        footerHeight = topConstrain  + bottomConstrain
        
//        if true {
//            if let firstButton = footer.button1  {
//                if let height = firstButton.styles.height {
//                    nextButton1Height.constant = height
//                }
//
//                footerHeight += nextButton1Height.constant
//            }
//        }
            
            
        if let firstButton = footer.button1 {
            if let height = firstButton.styles.height {
                nextButton1Height.constant = height
            }
            
            footerHeight += nextButton1Height.constant
        }
        
        if let secondButton = footer.button2 {
            if let height = secondButton.styles.height {
                nextButton2Height.constant = height
            }
            footerHeight += nextButton1Height.constant
        }
        
        if footer.button1 != nil &&  footer.button2 != nil {
            footerHeight += betweenButtonsConstrain
        }
        
        return footerHeight
    }

}

private extension OnboardingFooterVC {
    
    func setupNextButton() {
        
        if let nextButtonScreenData = footer.button1 {
            if let height = nextButtonScreenData.styles.height {
                nextButton1Height.constant = height
            }
            
            nextButton1.apply(button: nextButtonScreenData)
            if nextButtonScreenData.styles.fullWidth ?? true {
                leadingNextButtonConstraint.isActive = true
                trailingNextButtonConstraint.isActive = true
                centerNextButtonConstraint.isActive = false
            } else {
                leadingNextButtonConstraint.isActive = false
                trailingNextButtonConstraint.isActive = false
                centerNextButtonConstraint.isActive = true
            }
        } else {
            nextButton1.isHidden = true
            containerButton1.isHidden = true
        }
        
        if let nextButtonScreenData = footer.button2 {
            if let height = nextButtonScreenData.styles.height {
                nextButton2Height.constant = height
            }

            nextButton2.apply(button: nextButtonScreenData)
            if nextButtonScreenData.styles.fullWidth ?? true {
                secondButtonLeadingNextButtonConstraint.isActive = true
                secondButtonTrailingNextButtonConstraint.isActive = true
                secondButtonCenterNextButtonConstraint.isActive = false
            } else {
                secondButtonLeadingNextButtonConstraint.isActive = false
                secondButtonTrailingNextButtonConstraint.isActive = false
                secondButtonCenterNextButtonConstraint.isActive = true
            }
        } else {
            nextButton2.isHidden = true
            containerButton2.isHidden = true
        }
    }
    
    func runInitialAnimation() {
        OnboardingAnimation.runAnimationOfType(.fade, in: [nextButton1, nextButton2], delay: OnboardingAnimation.animationDuration)
    }

    @IBAction func firstButtonAction(_ sender: Any) {
        if let action  = footer.button1?.action, let callBack =  firstButtonAction {
            callBack(action)
        }
    }
    
    @IBAction func secondButtonAction(_ sender: Any) {
        if let action  = footer.button2?.action, let callBack =  secondButtonAction {
            callBack(action)
        }
    }
    
}


