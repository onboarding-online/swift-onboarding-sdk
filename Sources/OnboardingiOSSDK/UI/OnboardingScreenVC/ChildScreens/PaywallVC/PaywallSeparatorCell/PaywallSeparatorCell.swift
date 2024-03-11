//
//  PaywallSeparatorCell.swift
//  
//
//  Created by Oleg Kuplin on 26.12.2023.
//

import UIKit
import ScreensGraph


final class PaywallSeparatorCell: UICollectionViewCell {

    @IBOutlet private weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var separatorView: UIView!
    
    @IBOutlet private weak var separatorContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var separatorContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var separatorContainerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var separatorContainerTrailingConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setupCellWith(divider: Divider?) {
        if let divider = divider {
            separatorContainerTopConstraint.constant = divider.box.styles.paddingTop ?? 8
            separatorContainerBottomConstraint.constant = divider.box.styles.paddingBottom ?? 8
            separatorContainerLeadingConstraint.constant =  16 + (divider.box.styles.paddingLeft ?? 0)
            separatorContainerTrailingConstraint.constant = 16 + (divider.box.styles.paddingRight ?? 0)
//
            heightConstraint.constant = divider.styles.height ?? 1
            separatorView.backgroundColor = divider.styles.color?.hexStringToColor  ?? .clear
        } else {
            separatorView.isHidden = true
        }
    }
    
    static func calculateHeightFor(divider: Divider?) -> Double {
        if let divider = divider {
            let top = divider.box.styles.paddingTop ?? 8
            let bottom = divider.box.styles.paddingBottom ?? 8
            let heigh = divider.styles.height ?? 1

            let totalHeight = top + bottom + heigh
            return totalHeight

        } else {
            return 0.0
        }
    }

}
