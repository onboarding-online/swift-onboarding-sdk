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
    
    var titleLabel: UILabel!
    var subtitleLabel: UILabel!
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var textBottomBorderView: UIView!
    
    @IBOutlet weak var separatorView: UIView!

    @IBOutlet weak var textFieldTopConstraint: NSLayoutConstraint?
    @IBOutlet weak var textFieldLeftConstraint: NSLayoutConstraint?
    @IBOutlet weak var textFieldRightConstraint: NSLayoutConstraint?

    @IBOutlet weak var footerBottomConstraint: NSLayoutConstraint?

    @IBOutlet weak var mainStackView: UIStackView!

    
    var screenData: ScreenTitleSubtitleField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        textFieldTopConstraint?.constant = screenData.field.box.styles.paddingTop ?? 0.0
        
        textFieldLeftConstraint?.constant = screenData.field.box.styles.paddingLeft ?? 0.0
        textFieldRightConstraint?.constant = screenData.field.box.styles.paddingRight ?? 0.0

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
    
    
    func wrapLabelInUIView(label: UILabel, padding: BoxBlock? = nil) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        containerView.addSubview(label)
        
        containerView.setContentHuggingPriority(UILayoutPriority(300), for: .horizontal) // Для вертикального стека
        containerView.setContentCompressionResistancePriority(UILayoutPriority(800), for: .horizontal) // Для вертикальног
        
        let bottom = -1 * (padding?.paddingBottom ?? 0)
        var trailing = -1 * (padding?.paddingRight ?? 0)
        
        var leading = (padding?.paddingLeft ?? 0)
        let top = (padding?.paddingTop ?? 0)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: top),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: bottom),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: leading),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: trailing)
        ])
        
        return containerView
    }
    
    func buildLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0

        label.setContentHuggingPriority(UILayoutPriority(300), for: .horizontal)
        label.setContentCompressionResistancePriority(UILayoutPriority(800), for: .horizontal)

        label.setContentHuggingPriority(UILayoutPriority(1000), for: .vertical)
        label.setContentCompressionResistancePriority(UILayoutPriority(800), for: .vertical)
        
        return label
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
        
        titleLabel = buildLabel()
        subtitleLabel = buildLabel()
        
        let titleLabelView = wrapLabelInUIView(label: titleLabel, padding: screenData.title.box.styles)
        let subtitleLabelView = wrapLabelInUIView(label: subtitleLabel, padding: screenData.subtitle.box.styles)
        
        titleLabel.apply(text: screenData?.title)
        subtitleLabel.apply(text: screenData?.subtitle)
        
        if let text = titleLabel.text, !text.isEmpty {
            mainStackView.addArrangedSubview(titleLabelView)
        }
        
        if let text = subtitleLabel.text, !text.isEmpty {
            mainStackView.addArrangedSubview(subtitleLabelView)
        }
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

