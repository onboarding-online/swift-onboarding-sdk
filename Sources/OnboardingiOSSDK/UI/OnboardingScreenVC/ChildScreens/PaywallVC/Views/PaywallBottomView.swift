//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 26.12.2023.
//

import UIKit

protocol PaywallBottomViewDelegate: AnyObject {
    func paywallBottomViewBuyButtonPressed(_ paywallBottomView: PaywallBottomView)
    func paywallBottomViewPPButtonPressed(_ paywallBottomView: PaywallBottomView)
    func paywallBottomViewTACButtonPressed(_ paywallBottomView: PaywallBottomView)
    func paywallBottomViewRestoreButtonPressed(_ paywallBottomView: PaywallBottomView)
}

final class PaywallBottomView: UIView {
    
    private let sideOffset: CGFloat = { UIScreen.isIphoneSE1 ? 12 : 24 }()

    private var buyButtonWithInfoStack: UIStackView!
    private var buyButton: UIButton!
    private var ppButton: UIButton!
    private var tacButton: UIButton!
    private var restoreButton: UIButton!
    private var additionalInfoLabel: UILabel!
    
    weak var delegate: PaywallBottomViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
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
        delegate?.paywallBottomViewPPButtonPressed(self)
    }
    
    @objc func tacButtonPressed() {
        delegate?.paywallBottomViewTACButtonPressed(self)
    }
    
    @objc func restoreButtonPressed() {
        delegate?.paywallBottomViewRestoreButtonPressed(self)
    }
}

// MARK: - Setup methods
private extension PaywallBottomView {
    func setup() {
        backgroundColor = .systemBackground
        addBuyButtonWithInfoStack()
        addBuyButton()
        addInfoLabel()
        addEssentialButtonsStack()
    }
    
    func addBuyButtonWithInfoStack() {
        buyButtonWithInfoStack = createView()
        buyButtonWithInfoStack.axis = .vertical
        buyButtonWithInfoStack.alignment = .fill
        buyButtonWithInfoStack.spacing = UIScreen.isIphoneSE1 ? 8 : 16
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
        buyButtonWithInfoStack.addArrangedSubview(buyButton)
        buyButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
    }
    
    func addInfoLabel() {
        additionalInfoLabel = createView()
        additionalInfoLabel.textColor = .black.withAlphaComponent(0.6)
        additionalInfoLabel.font = .systemFont(ofSize: 15, weight: .regular)
        additionalInfoLabel.textAlignment = .center
        additionalInfoLabel.adjustsFontSizeToFitWidth = true
        additionalInfoLabel.text = "7 days free, then $39.99/year. Auto-renewable."
        buyButtonWithInfoStack.addArrangedSubview(additionalInfoLabel)
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
