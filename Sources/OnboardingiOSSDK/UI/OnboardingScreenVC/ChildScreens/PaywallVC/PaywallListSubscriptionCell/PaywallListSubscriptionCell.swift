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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentContainerView.layer.cornerRadius = 16
        contentContainerView.backgroundColor = .lightGray
        contentContainerView.layer.borderColor = UIColor.blue.cgColor
    }

}

// MARK: - Open methods
extension PaywallListSubscriptionCell {
    func setWith(configuration: PaywallVC.ListSubscriptionCellConfiguration,
                 isSelected: Bool) {
        checkbox.isOn = isSelected
        contentContainerView.layer.borderWidth = isSelected ? 1 : 0
    }
}
