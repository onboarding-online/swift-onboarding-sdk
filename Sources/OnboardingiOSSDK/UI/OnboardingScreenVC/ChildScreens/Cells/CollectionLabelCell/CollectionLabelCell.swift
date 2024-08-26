//
//  CollectionLabelCell.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 24.05.2023.
//

import UIKit
import ScreensGraph

final class CollectionLabelCell: UICollectionViewCell {

    @IBOutlet private weak var textLabel: UILabel!
    
    @IBOutlet weak var collectionLeftPadding: NSLayoutConstraint!
    @IBOutlet weak var collectionRightPadding: NSLayoutConstraint!

    @IBOutlet weak var collectionTopPadding: NSLayoutConstraint!
    @IBOutlet weak var collectionBottomPadding: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        textLabel.numberOfLines = 0
    }

}

// MARK: - Open methods
extension CollectionLabelCell {
    func setWithText(_ text: Text) {
        
        let box = text.box.styles
        collectionLeftPadding.constant = box.paddingLeft ?? 0.0
        collectionRightPadding.constant = box.paddingRight ?? 0.0
        collectionTopPadding.constant = box.paddingTop ?? 0.0
        collectionBottomPadding.constant = box.paddingBottom ?? 0.0

        textLabel.apply(text: text)
    }
}
