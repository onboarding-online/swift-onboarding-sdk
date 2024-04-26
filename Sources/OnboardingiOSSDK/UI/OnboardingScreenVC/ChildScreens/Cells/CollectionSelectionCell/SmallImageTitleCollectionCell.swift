//
//  CollectionSelectionCell.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 17.05.2023.
//

import UIKit
import ScreensGraph

final class SmallImageTitleCollectionCell: UICollectionViewCell, UIImageLoader {

    @IBOutlet private weak var backgroundContentView: UIView!

    @IBOutlet private weak var ImageContentView: UIView!
    @IBOutlet private weak var image: UIImageView!

    @IBOutlet private weak var title: UILabel!
    
    var currentItem: ItemTypeSelection?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.image.contentMode = .bottom
    }
    
    func setWith(list: TwoColumnMultipleSelectionList, item: ItemTypeSelection, isSelected: Bool,
                 useLocalAssetsIfAvailable: Bool) {
        title.apply(text: item.title)
        loadImageFor(item: item, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)

        if isSelected {
            backgroundContentView.apply(listStyle: list.selectedBlock.styles)
        } else {
            backgroundContentView.apply(listStyle: list.styles)
        }
        
        setupEmptyStateForTitleAndSubtitle()
    }
    
    func setWith(list: TwoColumnSingleSelectionList, item: ItemTypeSelection, isSelected: Bool,
                 useLocalAssetsIfAvailable: Bool) {
        title.apply(text: item.title)
        loadImageFor(item: item, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)

        if isSelected {
            backgroundContentView.apply(listStyle: list.selectedBlock.styles)
        } else {
            backgroundContentView.apply(listStyle: list.styles)
        }
        setupEmptyStateForTitleAndSubtitle()
    }
    
    func loadImageFor(item: ItemTypeSelection, useLocalAssetsIfAvailable: Bool) {
        if currentItem != item {
            setupImageContentMode(item: item)
            load(image: item.image, in: image, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
            currentItem = item
        }
    }
    
    func setupImageContentMode(item: ItemTypeSelection) {
        if let imageContentMode = item.image.imageContentMode() {
            image.contentMode = imageContentMode
        } else {
            image.contentMode = .scaleAspectFit
        }
    }
    
    func setupEmptyStateForTitleAndSubtitle() {
        if (title.text?.isEmpty ?? true) {
            title.text = " "
            title.isHidden = false
        }
    }
        
}

