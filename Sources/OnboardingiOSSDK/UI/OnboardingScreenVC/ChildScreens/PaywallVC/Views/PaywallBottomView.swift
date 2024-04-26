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
    
    public var buyButton: UIButton!
    var buyButtonContainer = UIView.init()

    
    private var ppButton: UIButton!
    private var tacButton: UIButton!
    private var restoreButton: UIButton!
    var buttonsContainer = UIView.init()

    
    var additionalInfoLabel: UILabel!
    var additionalInfoLabelContainer = UIView.init()

    var currencyFormatKind: CurrencyFormatKind?
    
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
        
        restoreButton.apply(textLabel: footer.bottomContainer.restore)
                                        
        tacButton.apply(navLink: footer.bottomContainer.termsOfUse)
        ppButton.apply(navLink: footer.bottomContainer.privacyPolicy)

        additionalInfoLabel.apply(text: footer.autoRenewLabel)
    }
    
    func setupPaymentDetailsLabel(content: String) {
        additionalInfoLabel.text = content
    }
    
    func setupPaymentDetailsLabel(content: StoreKitProduct, currencyFormat: CurrencyFormatKind?) {
        if let text = footer.autoRenewLabel?.textFor(product: content, currencyFormat: currencyFormatKind) {
            additionalInfoLabel.text = text
        }
        
        buyButton.apply(button: footer.purchase, product: content, currencyFormat: currencyFormatKind)
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
        delegate?.paywallBottomViewPPButtonPressed(self, url: footer.bottomContainer.privacyPolicy?.uri ?? "")
    }
    
    @objc func tacButtonPressed() {
        delegate?.paywallBottomViewTACButtonPressed(self, url: footer.bottomContainer.termsOfUse?.uri ?? "")
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
        if let order =  footer.styles.elementsOrder, order == .autoRenewLabelFirst {
            addInfoLabel()
            addBuyButton()
        } else {
            addBuyButton()
            addInfoLabel()
        }

        addEssentialButtonsStack()
    }
    
    func addBuyButtonWithInfoStack() {
        buyButtonWithInfoStack = createView()
        buyButtonWithInfoStack.axis = .vertical
        buyButtonWithInfoStack.alignment = .fill
//        buyButtonWithInfoStack.spacing = UIScreen.isIphoneSE1 ? 8 : 16
        
        buyButtonWithInfoStack.spacing = 0
        addSubview(buyButtonWithInfoStack)
        
        NSLayoutConstraint.activate([
            buyButtonWithInfoStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            buyButtonWithInfoStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            buyButtonWithInfoStack.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            buyButtonWithInfoStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        ])
    }
    
    func addBuyButton() {
        buyButton = createView()
//        buyButton.backgroundColor = .blue
//        buyButton.setTitle("Buy Now", for: .normal)
//        buyButton.layer.cornerRadius = 12
        buyButton.addTarget(self, action: #selector(buyButtonPressed), for: .touchUpInside)
        buyButtonWithInfoStack.addArrangedSubview(buyButton)
        
        let defaultHeight =  UIScreen.isIphoneSE1 ? 44.0 : 56.0
        let buttonHeight: CGFloat = footer.purchase?.styles.height ?? defaultHeight
        buyButton.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        
        buyButtonContainer.addSubview(buyButton)
        

        add(boxConstraint: footer.purchase?.box.styles, containerView: buyButtonContainer, subView: buyButton)
        
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
        
        add(boxConstraint: footer.autoRenewLabel?.box.styles, containerView: additionalInfoLabelContainer, subView: additionalInfoLabel)
        
        buyButtonWithInfoStack.addArrangedSubview(additionalInfoLabelContainer)
    }
    
    func add(boxConstraint: Paddings?, containerView: UIView, subView: UIView) {
        let top = boxConstraint?.paddingTop ?? 0
        var bottom = boxConstraint?.paddingBottom ?? 0
        let leading = boxConstraint?.paddingLeft ?? 0
        var trailing = boxConstraint?.paddingRight ?? 0

        trailing = trailing * -1
        bottom = bottom * -1

        
        NSLayoutConstraint.activate([
            subView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: leading),
            subView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: trailing),
            subView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: top),
            subView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: bottom),
        ])
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
                
        buttonsContainer.addSubview(stack)
        add(boxConstraint: footer.bottomContainer.styles, containerView: buttonsContainer, subView: stack)
        
        buyButtonWithInfoStack.addArrangedSubview(buttonsContainer)
    }
    
    func createView<T: UIView>() -> T {
        let view = T()
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }
}

protocol Paddings {
    /** Padding left for container */
    var paddingLeft: Double? { get }
    /** Padding right for container */
    var paddingRight: Double? { get }
    /** Padding top for container */
    var paddingTop: Double? { get }
    /** Padding bottom for container */
    var paddingBottom: Double? { get }
}

extension BoxBlock: Paddings {}

extension PaywallFooterBottomContainerBlock: Paddings {}
