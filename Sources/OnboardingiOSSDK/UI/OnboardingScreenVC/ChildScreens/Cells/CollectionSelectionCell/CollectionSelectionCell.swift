//
//  CollectionSelectionCell.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 17.05.2023.
//

import UIKit
import ScreensGraph

final class CollectionSelectionCell: UICollectionViewCell, UIImageLoader {

    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private weak var imageWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var title: UILabel!
    
    @IBOutlet private weak var backgroundContentView: UIStackView!

    @IBOutlet private weak var image: UIImageView!

    @IBOutlet private weak var textLabelHeightConstraint: NSLayoutConstraint!
    
    var currentItem: ItemTypeSelection?

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setWith(list: TwoColumnMultipleSelectionList, item: ItemTypeSelection, isSelected: Bool,
                 useLocalAssetsIfAvailable: Bool) {
        title.apply(text: item.title)
        loadImageFor(item: item,
                     useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)

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
        loadImageFor(item: item,
                     useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)

        if isSelected {
            backgroundContentView.apply(listStyle: list.selectedBlock.styles)
        } else {
            backgroundContentView.apply(listStyle: list.styles)
        }
        setupEmptyStateForTitleAndSubtitle()
    }
    
    func setupEmptyStateForTitleAndSubtitle() {
        if (title.text?.isEmpty ?? true) {
            title.text = " "
            title.isHidden = false
        }
    }
    
    func loadImageFor(item: ItemTypeSelection,
                      useLocalAssetsIfAvailable: Bool) {
        if currentItem != item {
            setupImageContentMode(item: item)
            load(image: item.image, in: image,
                 useLocalAssetsIfAvailable: useLocalAssetsIfAvailable, animated: false)
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
    
}
