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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        textLabel.numberOfLines = 0
    }

}

// MARK: - Open methods
extension CollectionLabelCell {
    func setWithText(_ text: Text) {
        textLabel.apply(text: text)
    }
}
