//
//  PaywallListSubscriptionCell.swift
//  
//
//  Created by Oleg Kuplin on 26.12.2023.
//

import UIKit

final class PaywallListSubscriptionCell: UICollectionViewCell {

    @IBOutlet private weak var contentContainerView: UIView!
    @IBOutlet private weak var checkbox: PaywallCheckboxView!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var pricePerMonthLabel: UILabel!
    @IBOutlet private weak var contentLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var savedMoneyView: SavedMoneyView!
    private var currentSavedMoneyViewConstraints: [NSLayoutConstraint] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        
        clipsToBounds = false
        savedMoneyView.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.layer.cornerRadius = 16
        contentContainerView.layer.borderColor = UIColor.blue.cgColor
        contentLeadingConstraint.constant = UIScreen.isIphoneSE1 ? 12 : 24
    }

}

// MARK: - Open methods
extension PaywallListSubscriptionCell {
    func setWith(configuration: PaywallVC.ListSubscriptionCellConfiguration,
                 isSelected: Bool) {
        checkbox.isOn = isSelected
        setBadgePosition(configuration.badgePosition)
        contentContainerView.layer.borderWidth = isSelected ? 1 : 0
        contentContainerView.backgroundColor = isSelected ? .white : .black.withAlphaComponent(0.05)

        if isSelected {
            contentContainerView.applyFigmaShadow(x: 0, y: 20, blur: 40, spread: 0, color: .black, alpha: 0.15)
        } else {
            contentContainerView.applyFigmaShadow(x: 0, y: 1, blur: 0, spread: 0, color: .black, alpha: 0.05)
        }
    }
}

// MARK: - Private methods
private extension PaywallListSubscriptionCell {
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
}

// MARK: - Open methods
extension PaywallListSubscriptionCell {
    enum SavedMoneyBadgePosition {
        case none, left, center, right
    }
}
