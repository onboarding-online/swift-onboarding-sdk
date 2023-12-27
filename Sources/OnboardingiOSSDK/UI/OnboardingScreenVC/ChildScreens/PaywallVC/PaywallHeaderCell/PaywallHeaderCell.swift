//
//  PaywallHeaderCell.swift
//  
//
//  Created by Oleg Kuplin on 26.12.2023.
//

import UIKit

final class PaywallHeaderCell: UICollectionViewCell {

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var gradientView: GradientView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        gradientView.gradientColors = [.clear, .white]
        gradientView.gradientDirection = .topToBottom
        clipsToBounds = false
    }

}

// MARK: - Open methods
extension PaywallHeaderCell {
    func setWith(configuration: PaywallVC.HeaderCellConfiguration) {
        titleLabel.text = configuration.title
        subtitleLabel.text = configuration.subtitle
        AssetsLoadingService.shared.loadImageFromURL(configuration.imageURL,
                                                     intoView: imageView,
                                                     placeholderImageName: nil)
    }
    
    func setScrollOffset(_ offset: CGPoint) {
        let offset = min(0, offset.y)
        imageViewTopConstraint.constant = offset
    }
}
