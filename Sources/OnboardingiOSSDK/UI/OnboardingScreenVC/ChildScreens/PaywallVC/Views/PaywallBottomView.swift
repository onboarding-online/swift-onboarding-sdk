//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 26.12.2023.
//

import UIKit
import ScreensGraph

protocol PaywallBottomViewDelegate: AnyObject {
    func paywallBottomViewBuyButtonPressed(_ paywallBottomView: PaywallBottomView)
    func paywallBottomViewPPButtonPressed(_ paywallBottomView: PaywallBottomView, url : String)
    func paywallBottomViewTACButtonPressed(_ paywallBottomView: PaywallBottomView, url : String)
    func paywallBottomViewRestoreButtonPressed(_ paywallBottomView: PaywallBottomView)
}

final class PaywallBottomView: UIView {
    
    private let sideOffset: CGFloat = { UIScreen.isIphoneSE1 ? 12 : 24 }()

    private var buyButtonWithInfoStack: UIStackView!
    
    private var buyButton: UIButton!
    var buyButtonContainer = UIView.init()

    
    private var ppButton: UIButton!
    private var tacButton: UIButton!
    private var restoreButton: UIButton!
    
    var additionalInfoLabel: UILabel!
    var additionalInfoLabelContainer = UIView.init()

    
    weak var delegate: PaywallBottomViewDelegate?
    
    private var footer: PaywallFooter! = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
//        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
    }
    
    func setup(footer: PaywallFooter) {
        self.footer = footer

        setup()

        buyButton.apply(button: footer.purchase)
        
        restoreButton.apply(button: footer.restore)
        
        tacButton.apply(navLink: footer.termsOfUse)
        ppButton.apply(navLink: footer.privacyPolicy)

        additionalInfoLabel.apply(text: footer.autoRenewLabel)
    }
    
    func setupPaymentDetailsLabel(content: String) {
        additionalInfoLabel.text = content
    }
    
    func setupPaymentDetailsLabel(content: StoreKitProduct) {
        if let text = footer.autoRenewLabel?.textFor(product: content) {
            additionalInfoLabel.text = text
        }
        
        buyButton.apply(button: footer.purchase, product: content)
    }
    
    func setupPaymentDetailsForPurchaseButtonWith(product: StoreKitProduct) {
//        if let text = footer.purchase?.textFor(product: content) {
//            additionalInfoLabel.text = text
//        }
    }
    
}

// MARK: - Open methods
extension PaywallBottomView {
    
}

// MARK: - Private methods
private extension PaywallBottomView {
    
    @objc func buyButtonPressed() {
        delegate?.paywallBottomViewBuyButtonPressed(self)
    }
    
    @objc func ppButtonPressed() {
        delegate?.paywallBottomViewPPButtonPressed(self, url: footer.privacyPolicy?.uri ?? "")
    }
    
    @objc func tacButtonPressed() {
        delegate?.paywallBottomViewTACButtonPressed(self, url: footer.privacyPolicy?.uri ?? "")
    }
    
    @objc func restoreButtonPressed() {
        delegate?.paywallBottomViewRestoreButtonPressed(self)
    }
    
}

// MARK: - Setup methods
private extension PaywallBottomView {
    func setup() {
//        backgroundColor = .white
        addBuyButtonWithInfoStack()
        addBuyButton()
        addInfoLabel()
        addEssentialButtonsStack()
    }
    
    func addBuyButtonWithInfoStack() {
        buyButtonWithInfoStack = createView()
        buyButtonWithInfoStack.axis = .vertical
        buyButtonWithInfoStack.alignment = .fill
//        buyButtonWithInfoStack.spacing = UIScreen.isIphoneSE1 ? 8 : 16
        
        buyButtonWithInfoStack.spacing = 0
        buyButtonWithInfoStack.backgroundColor = .red
        self.backgroundColor = .blue
        addSubview(buyButtonWithInfoStack)
        
        NSLayoutConstraint.activate([
            buyButtonWithInfoStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: sideOffset),
            buyButtonWithInfoStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            buyButtonWithInfoStack.topAnchor.constraint(equalTo: topAnchor, constant: 0)
        ])
    }
    
    func addBuyButton() {
        buyButton = createView()
        buyButton.backgroundColor = .blue
        buyButton.setTitle("Buy Now", for: .normal)
        buyButton.layer.cornerRadius = 12
        buyButton.addTarget(self, action: #selector(buyButtonPressed), for: .touchUpInside)
        buyButtonWithInfoStack.addArrangedSubview(buyButton)
        let buttonHeight: CGFloat = UIScreen.isIphoneSE1 ? 44 : 56
        buyButton.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        
        buyButtonContainer.addSubview(buyButton)
        
        let top = footer.purchase?.box.styles.paddingTop ?? 0
        let bottom = footer.purchase?.box.styles.paddingBottom ?? 0
        let leading = footer.purchase?.box.styles.paddingLeft ?? 0
        var trailing = footer.purchase?.box.styles.paddingRight ?? 0

        trailing = trailing * -1
        
        NSLayoutConstraint.activate([
            buyButton.leadingAnchor.constraint(equalTo: buyButtonContainer.leadingAnchor, constant: leading),
            buyButton.trailingAnchor.constraint(equalTo: buyButtonContainer.trailingAnchor, constant: trailing),
            buyButton.topAnchor.constraint(equalTo: buyButtonContainer.topAnchor, constant: top),
            buyButton.bottomAnchor.constraint(equalTo: buyButtonContainer.bottomAnchor, constant: bottom),
        ])
        
        buyButtonWithInfoStack.addArrangedSubview(buyButtonContainer)
        
    }
    
    func addInfoLabel() {
        additionalInfoLabel = createView()
        additionalInfoLabel.textColor = .black.withAlphaComponent(0.6)
        additionalInfoLabel.font = .systemFont(ofSize: 15, weight: .regular)
        additionalInfoLabel.textAlignment = .center
        additionalInfoLabel.adjustsFontSizeToFitWidth = true
        additionalInfoLabel.text = "7 days free, then $39.99/year. Auto-renewable."
        
        additionalInfoLabelContainer.addSubview(additionalInfoLabel)
        
        let top = footer.autoRenewLabel?.box.styles.paddingTop ?? 0
        let bottom = footer.autoRenewLabel?.box.styles.paddingBottom ?? 0
        let leading = footer.autoRenewLabel?.box.styles.paddingLeft ?? 0
        var trailing = footer.autoRenewLabel?.box.styles.paddingRight ?? 0

        trailing = trailing * -1
        
        NSLayoutConstraint.activate([
            additionalInfoLabel.leadingAnchor.constraint(equalTo: additionalInfoLabelContainer.leadingAnchor, constant: leading),
            additionalInfoLabel.trailingAnchor.constraint(equalTo: additionalInfoLabelContainer.trailingAnchor, constant: trailing),
            additionalInfoLabel.topAnchor.constraint(equalTo: additionalInfoLabelContainer.topAnchor, constant: top),
            additionalInfoLabel.bottomAnchor.constraint(equalTo: additionalInfoLabelContainer.bottomAnchor, constant: bottom),
        ])
        
        buyButtonWithInfoStack.addArrangedSubview(additionalInfoLabelContainer)

    }
    
    func addEssentialButtonsStack() {
        ppButton = createView()
        ppButton.setTitle("Privacy Policy", for: .normal)
        ppButton.addTarget(self, action: #selector(ppButtonPressed), for: .touchUpInside)
        tacButton = createView()
        tacButton.setTitle("Terms of Use", for: .normal)
        tacButton.addTarget(self, action: #selector(tacButtonPressed), for: .touchUpInside)
        restoreButton = createView()
        restoreButton.setTitle("Restore", for: .normal)
        restoreButton.addTarget(self, action: #selector(restoreButtonPressed), for: .touchUpInside)
        
        [ppButton, tacButton, restoreButton].forEach { button in
            button?.titleLabel?.font = .systemFont(ofSize: 13, weight: .regular)
            button?.setTitleColor(.black.withAlphaComponent(0.6), for: .normal)
        }
        
        let stack = UIStackView(arrangedSubviews: [ppButton, restoreButton, tacButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        
//        buyButtonWithInfoStack.addArrangedSubview(stack)

        addSubview(stack)
        
        let bottomOffset: CGFloat = UIScreen.isIphoneSE1 ? 8 : 16
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: sideOffset),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.topAnchor.constraint(equalTo: buyButtonWithInfoStack.bottomAnchor, constant: sideOffset),
            bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: bottomOffset)
        ])
    }
    
    func createView<T: UIView>() -> T {
        let view = T()
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }
}
