//
//  PaywallTileSubscriptionCell.swift
//  
//
//  Created by Oleg Kuplin on 27.01.2024.
//

import UIKit

final class PaywallTileSubscriptionCell: UICollectionViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}

// MARK: - Open methods
extension PaywallTileSubscriptionCell {
    func setWith(configuration: PaywallVC.ListSubscriptionCellConfiguration,
                 isSelected: Bool) {
        backgroundColor = isSelected ? .red : .green
//        setBadgePosition(configuration.badgePosition)
//        setSelected(isSelected)
//        
//        let subscriptionDescription = configuration.subscriptionDescription
//        let periodUnitName = subscriptionDescription.periodLocalizedUnitName
//        let price = subscriptionDescription.localizedPrice
//        
//        durationLabel.text = periodUnitName
//        priceLabel.text = price
    }
}
