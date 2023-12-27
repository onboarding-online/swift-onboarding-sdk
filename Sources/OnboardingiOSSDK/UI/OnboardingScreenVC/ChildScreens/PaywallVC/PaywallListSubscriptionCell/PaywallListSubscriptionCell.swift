//
//  PaywallListSubscriptionCell.swift
//  
//
//  Created by Oleg Kuplin on 26.12.2023.
//

import UIKit

final class PaywallListSubscriptionCell: UICollectionViewCell {

    @IBOutlet private weak var contentContainerView: UIView!
    @IBOutlet private weak var checkboxImageView: UIImageView!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var pricePerMonthLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentContainerView.layer.cornerRadius = 16
        contentContainerView.backgroundColor = .lightGray
    }

}

// MARK: - Open methods
extension PaywallListSubscriptionCell {
    func setWith(configuration: PaywallVC.ListSubscriptionCellConfiguration) {
        
    }
}
