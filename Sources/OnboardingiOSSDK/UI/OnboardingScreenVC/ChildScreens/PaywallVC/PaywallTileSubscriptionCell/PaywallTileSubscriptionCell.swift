//
//  PaywallTileSubscriptionCell.swift
//  
//
//  Created by Oleg Kuplin on 27.01.2024.
//

import UIKit

final class PaywallTileSubscriptionCell: UICollectionViewCell {

    @IBOutlet private weak var contentContainerView: UIView!
    @IBOutlet private weak var checkboxStackContainer: UIStackView!
    @IBOutlet private weak var checkbox: PaywallCheckboxView!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var pricePerMonthLabel: UILabel!
    @IBOutlet private weak var savedMoneyView: SavedMoneyView!
    @IBOutlet private weak var checkboxStackContainerTopConstraint: NSLayoutConstraint!
    private var currentSavedMoneyViewConstraints: [NSLayoutConstraint] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        
        clipsToBounds = false
        checkbox.offBorderColor = .gray
        savedMoneyView.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.layer.cornerRadius = 16
        contentContainerView.layer.borderColor = UIColor.link.cgColor
    }

}

// MARK: - Open methods
extension PaywallTileSubscriptionCell {
    func setWith(configuration: PaywallVC.TileSubscriptionCellConfiguration,
                 isSelected: Bool) {
        setBadgePosition(configuration.badgePosition)
        setCheckmarkPosition(configuration.checkmarkPosition)
        setSelected(isSelected)
        
        let subscriptionDescription = configuration.subscriptionDescription
        let periodUnitName = subscriptionDescription.periodLocalizedUnitName
        let price = subscriptionDescription.localizedPrice
        
        durationLabel.text = periodUnitName
        pricePerMonthLabel.text = "\(price)/Month"
    }
}

// MARK: - Private methods
private extension PaywallTileSubscriptionCell {
    func setSelected(_ isSelected: Bool) {
        checkbox.isOn = isSelected
        contentContainerView.layer.borderWidth = isSelected ? 1 : 0
        contentContainerView.backgroundColor = isSelected ? .white : .systemGray6
        
        if isSelected {
            contentContainerView.applyFigmaShadow(x: 0, y: 20, blur: 40, spread: 0, color: .black, alpha: 0.15)
        } else {
            contentContainerView.applyFigmaShadow(x: 0, y: 1, blur: 0, spread: 0, color: .black, alpha: 0.05)
        }
    }
    
    func setBadgePosition(_ position: SavedMoneyBadgePosition) {
        savedMoneyView.isHidden = position == .none
        NSLayoutConstraint.deactivate(currentSavedMoneyViewConstraints)
        
        var constraints: [NSLayoutConstraint] = [savedMoneyView.heightAnchor.constraint(equalToConstant: 24),
                                                 savedMoneyView.centerYAnchor.constraint(equalTo: topAnchor)]
        switch position {
        case .none:
            return
        case .left:
            constraints.append(savedMoneyView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: 16))
        case .center:
            constraints.append(savedMoneyView.centerXAnchor.constraint(equalTo: centerXAnchor))
        case .right:
            constraints.append(contentContainerView.trailingAnchor.constraint(equalTo: savedMoneyView.trailingAnchor, constant: 16))
        }
        
        NSLayoutConstraint.activate(constraints)
        currentSavedMoneyViewConstraints = constraints
    }
    
    func setCheckmarkPosition(_ position: CheckmarkPosition) {
        
        switch position {
        case .left:
            checkboxStackContainerTopConstraint.constant = 20
            checkboxStackContainer.alignment = .leading
        case .center:
            checkboxStackContainerTopConstraint.constant = 30
            checkboxStackContainer.alignment = .center
        }
    }
}

// MARK: - Open methods
extension PaywallTileSubscriptionCell {
    enum SavedMoneyBadgePosition {
        case none, left, center, right
    }
    
    enum CheckmarkPosition {
        case left, center
    }
}