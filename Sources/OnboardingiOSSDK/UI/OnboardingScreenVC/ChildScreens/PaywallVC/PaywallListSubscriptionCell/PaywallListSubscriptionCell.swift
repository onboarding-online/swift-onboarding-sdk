//
//  PaywallListSubscriptionCell.swift
//  
//
//  Created by Oleg Kuplin on 26.12.2023.
//

import UIKit
import ScreensGraph

final class PaywallListSubscriptionCell: UICollectionViewCell {

    @IBOutlet private weak var contentContainerView: UIView!
    @IBOutlet private weak var checkbox: PaywallCheckboxView!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var pricePerMonthLabel: UILabel!
    @IBOutlet private weak var contentLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var savedMoneyView: SavedMoneyView!
    private var currentSavedMoneyViewConstraints: [NSLayoutConstraint] = []
    
    private var item: ItemTypeSubscription! = nil

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
    
//    func setWith(configuration: PaywallVC.ListSubscriptionCellConfiguration,
//                 isSelected: Bool) {
//        setBadgePosition(configuration.badgePosition)
//        setSelected(isSelected)
//
//        let subscriptionDescription = configuration.subscriptionDescription
//        let periodUnitName = subscriptionDescription.periodLocalizedUnitName
//        let price = subscriptionDescription.localizedPrice
//
//        durationLabel.text = periodUnitName
//        priceLabel.text = price
//    }
    
    func setWith(configuration: PaywallVC.ListSubscriptionCellConfiguration,
                    isSelected: Bool,
                    subscriptionItem: ItemTypeSubscription, listWithStyles: SubscriptionList) {
        self.item = subscriptionItem
        
        setBadgePosition(configuration.badgePosition, settings: item.badge)
        setSelected(isSelected, listWithStyles: listWithStyles)
        
        setupLabels(configuration: configuration, subscriptionItem: subscriptionItem)
    }
    
    func setupLabels(configuration: PaywallVC.ListSubscriptionCellConfiguration, subscriptionItem: ItemTypeSubscription) {
        let subscriptionDescription = configuration.subscriptionDescription
        let periodUnitName = subscriptionDescription.periodLocalizedUnitName
        let price = subscriptionDescription.localizedPrice
                
        durationLabel.apply(text: subscriptionItem.period)
        priceLabel.apply(text: subscriptionItem.price)
        pricePerMonthLabel.apply(text: subscriptionItem.description)
        
//      replace <price/>, <duration/> -- price, periodUnitName
        durationLabel.text =  durationLabel.text ?? "" + periodUnitName
        priceLabel.text = priceLabel.text ?? "" + price
        
        pricePerMonthLabel.text =  subscriptionDescription.trialDescription?.periodDuration.title
    }
    
    func setWith(configuration: PaywallVC.ListOneTimePurchaseCellConfiguration,
                 isSelected: Bool) {
        // TODO: - Use different cell
//        setBadgePosition(configuration.badgePosition)
//        setSelected(isSelected)
    }
}

// MARK: - Private methods
private extension PaywallListSubscriptionCell {
    
    func setSelected(_ isSelected: Bool, listWithStyles: SubscriptionList) {
        checkbox.isOn = isSelected
        
        if isSelected {
            setSelected(selectedBlock: listWithStyles.selectedBlock)
        } else {
            setDefault(style: listWithStyles.styles)
        }
    }
    
    func setDefault(style: SubscriptionListBlock) {
        contentContainerView.layer.borderWidth = style.borderWidth ?? 0
        contentContainerView.layer.borderColor = style.borderColor?.hexStringToColor.cgColor
        contentContainerView.backgroundColor = style.backgroundColor?.hexStringToColor ?? .black.withAlphaComponent(0.05)
        
        contentContainerView.applyFigmaShadow(x: 0, y: 1, blur: 0, spread: 0, color: .black, alpha: 0.05)
    }
    
    func setSelected(selectedBlock: SelectedSubscriptionListItemBlock) {
        contentContainerView.layer.borderWidth = selectedBlock.styles.borderWidth ?? 0
        contentContainerView.layer.borderColor = selectedBlock.styles.borderColor?.hexStringToColor.cgColor
        contentContainerView.backgroundColor = selectedBlock.styles.backgroundColor?.hexStringToColor ?? .black.withAlphaComponent(0.05)
        
        contentContainerView.applyFigmaShadow(x: 0, y: 20, blur: 40, spread: 0, color: .black, alpha: 0.15)
    }
    
    
    func setBadgePosition(_ position: SavedMoneyBadgePosition, settings: Badge?) {
       
        NSLayoutConstraint.deactivate(currentSavedMoneyViewConstraints)

        var constraints: [NSLayoutConstraint] = [savedMoneyView.heightAnchor.constraint(equalToConstant: 24),
                                                 savedMoneyView.centerYAnchor.constraint(equalTo: topAnchor)]
        
        if let badge = settings {
            savedMoneyView.isHidden = false
            
            savedMoneyView.layer.borderWidth = badge.styles.borderWidth ?? 0
            savedMoneyView.layer.cornerRadius = badge.styles.borderRadius ?? 0

            switch badge.styles.position {
            case .topleft:
                constraints.append(savedMoneyView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: 16))
            case .topcenter:
                constraints.append(savedMoneyView.centerXAnchor.constraint(equalTo: centerXAnchor))
            case .topright:
                constraints.append(contentContainerView.trailingAnchor.constraint(equalTo: savedMoneyView.trailingAnchor, constant: 16))
            default:
                return
            }
        } else {
            savedMoneyView.isHidden = true
        }
        
        NSLayoutConstraint.activate(constraints)
        currentSavedMoneyViewConstraints = constraints
    }
    
    
//    func setBadgePosition(_ position: SavedMoneyBadgePosition, settings: Badge?) {
//        savedMoneyView.isHidden = position == .none
//        NSLayoutConstraint.deactivate(currentSavedMoneyViewConstraints)
//
//        var constraints: [NSLayoutConstraint] = [savedMoneyView.heightAnchor.constraint(equalToConstant: 24),
//                                                 savedMoneyView.centerYAnchor.constraint(equalTo: topAnchor)]
//        switch position {
//        case .none:
//            return
//        case .left:
//            constraints.append(savedMoneyView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: 16))
//        case .center:
//            constraints.append(savedMoneyView.centerXAnchor.constraint(equalTo: centerXAnchor))
//        case .right:
//            constraints.append(contentContainerView.trailingAnchor.constraint(equalTo: savedMoneyView.trailingAnchor, constant: 16))
//        }
//
//        NSLayoutConstraint.activate(constraints)
//        currentSavedMoneyViewConstraints = constraints
//    }
}

// MARK: - Open methods
extension PaywallListSubscriptionCell {
    enum SavedMoneyBadgePosition {
        case none, left, center, right
    }
}
