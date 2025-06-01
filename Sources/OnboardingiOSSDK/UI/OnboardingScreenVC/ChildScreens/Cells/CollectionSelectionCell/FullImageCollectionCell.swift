//
//  CollectionSelectionCell.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 17.05.2023.
//

import UIKit
import ScreensGraph

final class FullImageCollectionCell: UICollectionViewCell, UIImageLoader {

    @IBOutlet private weak var backgroundContentView: UIView!

    @IBOutlet private weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var ImageContentView: UIView!
    @IBOutlet private weak var image: UIImageView!
    
    var currentItem: ItemTypeSelection?
    var useLocalAssetsIfAvailable: Bool = true

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.image.contentMode = .scaleToFill
    }
    
    func setWith(list: TwoColumnMultipleSelectionList, item: ItemTypeSelection, isSelected: Bool,
                 useLocalAssetsIfAvailable: Bool) {
        loadImageFor(item: item)

        if isSelected {
            backgroundContentView.apply(listStyle: list.selectedBlock.styles)
        } else {
            backgroundContentView.apply(listStyle: list.styles)
        }
    }
    
    
    func setWith(list: TwoColumnSingleSelectionList, item: ItemTypeSelection, isSelected: Bool,
                 useLocalAssetsIfAvailable: Bool) {
        loadImageFor(item: item)
                        
        if isSelected {
            backgroundContentView.apply(listStyle: list.selectedBlock.styles)
        } else {
            backgroundContentView.apply(listStyle: list.styles)
        }
    }
    
    
    private func loadImageFor(item: ItemTypeSelection) {
        if currentItem != item {
            setupImageContentMode(item: item)
            load(image: item.image, in: image, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable, animated: false)
            currentItem = item
        }
    }
    
    private func setupImageContentMode(item: ItemTypeSelection) {
        if let imageContentMode = item.image.imageContentMode() {
            image.contentMode = imageContentMode
        } else {
            image.contentMode = .scaleToFill
        }
    }
    
}
