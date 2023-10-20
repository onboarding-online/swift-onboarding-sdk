//
//  StoryboardExampleViewController.swift
//
//  Onboarding.online
//  Copyright 2023 Onboarding.online. All rights reserved.
//

import UIKit
import ScreensGraph

class ScreenTitleSubtitleFieldVC: BaseChildScreenGraphViewController {

    static func instantiate(screenData: ScreenTitleSubtitleField) -> ScreenTitleSubtitleFieldVC {
        let titleSubtitleFieldVC = ScreenTitleSubtitleFieldVC.storyBoardInstance()
        titleSubtitleFieldVC.screenData = screenData

        return titleSubtitleFieldVC
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var textBottomBorderView: UIView!
    
    @IBOutlet weak var separatorView: UIView!

    @IBOutlet weak var footerBottomConstraint: NSLayoutConstraint?

    var screenData: ScreenTitleSubtitleField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        setupLabelsValue()
        setupTextField()
    }
    
    override func runInitialAnimation() {
        super.runInitialAnimation()
        
        OnboardingAnimation.runAnimationOfType(.moveAndFade(direction: .fromBottomToTop), in: [titleLabel, subtitleLabel])
        OnboardingAnimation.runAnimationOfType(.fade, in: [textField])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        footerBottomConstraint?.constant = self.view.bounds.height / 2.3
        self.delegate?.onboardingChildScreenUpdate(value: textField.text, description: nil, logAnalytics: false)
        addKeyboardListeners()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    
        removeKeyboardListener()
    }
    
}

extension ScreenTitleSubtitleFieldVC: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.delegate?.onboardingChildScreenUpdate(value: textField.text, description: nil, logAnalytics: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.delegate?.onboardingChildScreenUpdate(value: textField.text, description: nil, logAnalytics: true)

        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text as? NSString {
            let newString = text.replacingCharacters(in: range, with: string)
            
            self.delegate?.onboardingChildScreenUpdate(value: newString, description: nil, logAnalytics: false)
        }

        return true
    }
    
}

private extension ScreenTitleSubtitleFieldVC {

    func setupLabelsValue() {
        titleLabel.apply(text: screenData?.title)
        subtitleLabel.apply(text: screenData?.subtitle)
    }
    
    func setupTextField() {
        if let color = screenData.field.styles.borderColor?.hexStringToColor {
            separatorView.backgroundColor = color
        }
        textField.delegate = self
        textField.apply(field: screenData.field)
    }
    
    func addKeyboardListeners() {
        // Notifications for when the keyboard opens/closes
         NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        DispatchQueue.main.async {[weak self] in
            self?.footerBottomConstraint?.constant = 0
            self?.textField.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        DispatchQueue.main.async {[weak self] in
            if let strongSelf = self {
                strongSelf.footerBottomConstraint?.constant = strongSelf.view.bounds.height / 2.3
            }
        }
    }
    
    func removeKeyboardListener() {
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }
}

