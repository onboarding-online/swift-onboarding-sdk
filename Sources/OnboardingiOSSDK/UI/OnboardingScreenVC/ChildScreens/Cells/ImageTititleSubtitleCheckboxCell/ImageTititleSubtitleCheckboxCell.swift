//
//  EatingScheduleCell.swift
//  IntuitiveEating
//
//
//  Copyright 2023 Onboarding.online on 09.03.2023.
//

import UIKit
import ScreensGraph


final class ImageTititleSubtitleCheckboxCell: UITableViewCell, UIImageLoader {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var checkbox: UIImageView!

    @IBOutlet weak var stackView: UIStackView!

    @IBOutlet weak var backgroundContentView: UIView!

    func setWith(item: ItemTypeSelection, styles: ListBlock, isSelected: Bool, useLocalAssetsIfAvailable: Bool) {
        titleLabel.apply(text: item.title)
        subtitleLabel.apply(text: item.subtitle)
        setupImage(item: item, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
        
        checkbox.apply(checkbox: item.checkBox, isSelected: isSelected)

        backgroundContentView.apply(listStyle: styles)
    }
    
    func setupImagesInStackView() {
        checkbox.removeFromSuperview()
        cellImage.removeFromSuperview()
    
        stackView.insertArrangedSubview(checkbox, at: 0)
        stackView.insertArrangedSubview(cellImage, at: 2)
        
        stackView.setNeedsLayout()
        stackView.layoutIfNeeded()
    }
    
    private func setupImage(item: ItemTypeSelection, useLocalAssetsIfAvailable: Bool) {
        load(image: item.image, in: cellImage, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
    }
    
    func setupUIBy(type: SingleSelectionListItemType) {
        checkbox.isHidden = true

        switch type {
        case .titleImage:
            subtitleLabel.isHidden = true
            setupImagesInStackView()
        case .imageTitle:
            subtitleLabel.isHidden = true
        case .imageTitleSubtitle:
            break
        case .titleSubtitleImage:
            setupImagesInStackView()
        case .titleSubtitle:
            cellImage.isHidden = true
        case .title:
            cellImage.isHidden = true
            subtitleLabel.isHidden = true
        }
    }
    
    func setupUIBy(type: MultipleSelectionListItemType) {
        switch type {
        case .imageTitleSubtitleCheckbox:
            break
        case .checkboxTitleSubtitleImage:
            setupImagesInStackView()
        case .imageTitleCheckbox:
            subtitleLabel.isHidden = true
        case .checkboxTitleImage:
            subtitleLabel.isHidden = true
            setupImagesInStackView()
        case .titleCheckbox:
            subtitleLabel.isHidden = true
            cellImage.isHidden = true
        case .checkboxTitle:
            setupImagesInStackView()
        case .titleImage:
            subtitleLabel.isHidden = true
            checkbox.isHidden = true
            setupImagesInStackView()
        case .imageTitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
        case .imageTitleSubtitle:
            checkbox.isHidden = true
        case .titleSubtitleImage:
            checkbox.isHidden = true
            setupImagesInStackView()
        case .titleSubtitle:
            checkbox.isHidden = true
            cellImage.isHidden = true
        case .title:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
            cellImage.isHidden = true
        case .titleSubtitleCheckbox:
            cellImage.isHidden = true
        case .checkboxTitleSubtitle:
            cellImage.isHidden = true
            setupImagesInStackView()
        }
    }
    
    
    
    func setupUIBy(type: TwoColumnMultipleSelectionListItemType) {
        switch type {
        case .tittle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
            cellImage.isHidden = true
        case .titleSubtitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = false
            cellImage.isHidden = true
        case .smallImageTitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
        case .mediumImageTitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
        case .fullImage:
            checkbox.isHidden = true
            subtitleLabel.isHidden = false
            titleLabel.isHidden = false

        case .bigImageTitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
        }
    }
    
    func setupUIBy1(type: TwoColumnSingleSelectionListItemType) {
        switch type {
        case .tittle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
            cellImage.isHidden = true
        case .titleSubtitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = false
            cellImage.isHidden = true
        case .smallImageTitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
        case .mediumImageTitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
        case .fullImage:
            checkbox.isHidden = true
            subtitleLabel.isHidden = false
            titleLabel.isHidden = false

        case .bigImageTitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
        }
    }
    
    func setupUIBy(type: RegularListItemType) {
        switch type {

        case .imageTitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
        case .titleImage:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
            
        }
    }
    
}
