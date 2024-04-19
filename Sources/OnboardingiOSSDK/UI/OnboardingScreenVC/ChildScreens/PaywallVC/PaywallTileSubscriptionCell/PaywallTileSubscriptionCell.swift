//
//  PaywallTileSubscriptionCell.swift
//  
//
//  Created by Oleg Kuplin on 27.01.2024.
//

import UIKit
import ScreensGraph

final class PaywallTileSubscriptionCell: UICollectionViewCell {

    @IBOutlet private weak var contentContainerView: UIView!
    @IBOutlet private weak var checkboxStackContainer: UIStackView!
    
    @IBOutlet private weak var labelsStackContainer: UIStackView!

    @IBOutlet private weak var mainContainerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mainContainerTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mainContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mainContainerBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var checkbox: UIImageView!
    @IBOutlet private weak var checkBoxContainerView: UIView!
    
    @IBOutlet private weak var checkBoxHeight: NSLayoutConstraint!
    @IBOutlet private weak var checkBoxWidth: NSLayoutConstraint!
    @IBOutlet private weak var checkBoxLeading: NSLayoutConstraint!
    @IBOutlet private weak var checkBoxTrailing: NSLayoutConstraint!
    @IBOutlet private weak var checkBoxBot: NSLayoutConstraint!
    @IBOutlet private weak var checkBoxTop: NSLayoutConstraint!

    
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var pricePerMonthLabel: UILabel!
    var savedMoneyView: SavedMoneyView = SavedMoneyView()
    @IBOutlet private weak var checkboxStackContainerTopConstraint: NSLayoutConstraint!
    private var currentSavedMoneyViewConstraints: [NSLayoutConstraint] = []
    
    private var item: ItemTypeSubscription! = nil
    var currencyFormatKind: CurrencyFormatKind?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        clipsToBounds = false
        setupBadge()
    }
    
}

// MARK: - Open methods
extension PaywallTileSubscriptionCell {

    func setWith(isSelected: Bool,
                    subscriptionItem: ItemTypeSubscription, listWithStyles: SubscriptionList,  product: StoreKitProduct) {
        self.item = subscriptionItem
        
        checkbox.apply(checkbox: subscriptionItem.checkBox, isSelected: isSelected)

                            
        setBadgePosition(settings: item.badge)
        setSelected(isSelected, listWithStyles: listWithStyles)
        
        setupLabels(subscriptionItem: subscriptionItem, product: product)
        setupCheckboxWith(list: listWithStyles)
        setupCheckBoxSizes(subscriptionItem: subscriptionItem)
        
        mainContainerBottomConstraint.constant = listWithStyles.styles.paddingBottom ?? 0
        mainContainerTopConstraint.constant = listWithStyles.styles.paddingTop ?? 0
        mainContainerTrailingConstraint.constant = listWithStyles.styles.paddingRight ?? 0
        mainContainerLeadingConstraint.constant = listWithStyles.styles.paddingLeft ?? 0

    }
    
    func setupLabels(subscriptionItem: ItemTypeSubscription, product: StoreKitProduct) {
        durationLabel.apply(text: subscriptionItem.leftLabelTop)
        pricePerMonthLabel.apply(text: subscriptionItem.leftLabelBottom)
        
        durationLabel.text =  subscriptionItem.leftLabelTop.textFor(product: product, currencyFormat: currencyFormatKind)
        pricePerMonthLabel.text = subscriptionItem.leftLabelBottom.textFor(product: product, currencyFormat: currencyFormatKind)
    }
    
}

// MARK: - Private methods
private extension PaywallTileSubscriptionCell {
    
    func setSelected(_ isSelected: Bool, listWithStyles: SubscriptionList) {
        if isSelected {
            setSelected(selectedBlock: listWithStyles.selectedBlock)
        } else {
            setDefault(style: listWithStyles.styles)
        }
    }
    
    func setDefault(style: SubscriptionListBlock) {
        contentContainerView.layer.borderWidth = style.borderWidth ?? 0
        contentContainerView.layer.borderColor = (style.borderColor?.hexStringToColor ?? .clear).cgColor
        contentContainerView.layer.cornerRadius = style.borderRadius ?? 0
        
        contentContainerView.backgroundColor = style.backgroundColor?.hexStringToColor ?? .clear
        
        contentContainerView.applyFigmaShadow(x: 0, y: 1, blur: 0, spread: 0, color: .black, alpha: 0.05)
    }
    
    func setSelected(selectedBlock: SelectedSubscriptionListItemBlock) {
        contentContainerView.layer.borderWidth = selectedBlock.styles.borderWidth ?? 0
        contentContainerView.layer.borderColor = (selectedBlock.styles.borderColor?.hexStringToColor ?? .clear).cgColor
        contentContainerView.layer.cornerRadius = selectedBlock.styles.borderRadius ?? 0

        contentContainerView.backgroundColor = selectedBlock.styles.backgroundColor?.hexStringToColor ?? .clear

        contentContainerView.applyFigmaShadow(x: 0, y: 20, blur: 40, spread: 0, color: .black, alpha: 0.15)
    }
    
    func setBadgePosition(settings: Badge?) {
        if let badge = settings {
            savedMoneyView.removeConstraints(savedMoneyView.constraints)
            
            NSLayoutConstraint.activate([
                savedMoneyView.heightAnchor.constraint(equalToConstant: 24),
                savedMoneyView.topAnchor.constraint(equalTo: self.topAnchor, constant: -12),
                savedMoneyView.label.topAnchor.constraint(equalTo: savedMoneyView.topAnchor, constant: 0),
                savedMoneyView.label.bottomAnchor.constraint(equalTo: savedMoneyView.bottomAnchor, constant: 0),
                savedMoneyView.label.leadingAnchor.constraint(equalTo: savedMoneyView.leadingAnchor, constant: 6),
                savedMoneyView.label.trailingAnchor.constraint(equalTo: savedMoneyView.trailingAnchor, constant: -6),
            ])

            savedMoneyView.isHidden = false
            
            savedMoneyView.backgroundColor = badge.styles.backgroundColor?.hexStringToColor ?? UIColor.clear
            
            savedMoneyView.layer.borderWidth = badge.styles.borderWidth ?? 0
            savedMoneyView.layer.cornerRadius = badge.styles.borderRadius ?? 0
            savedMoneyView.layer.borderColor = badge.styles.borderColor?.hexStringToColor.cgColor ?? UIColor.clear.cgColor

            savedMoneyView.label.apply(badge: settings)
            switch badge.styles.position {
            case .topleft:
                savedMoneyView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: 16).isActive = true
            case .topcenter:
                savedMoneyView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            case .topright:
                savedMoneyView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor, constant: -16).isActive = true
            default:
                savedMoneyView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: 16).isActive = true
            }
        } else {
            savedMoneyView.isHidden = true
        }
    }
    
    func setupCheckboxWith(list: SubscriptionList) {
        switch list.itemType {
        case .checkboxLabels:
//            checkboxStackContainerTopConstraint.constant = 20
            NSLayoutConstraint.activate([
                labelsStackContainer.topAnchor.constraint(equalTo: checkboxStackContainer.bottomAnchor, constant: 0),
            ])
            
            checkboxStackContainer.alignment = .leading
        case .labelsCheckbox:
            NSLayoutConstraint.activate([
                labelsStackContainer.topAnchor.constraint(equalTo: checkboxStackContainer.bottomAnchor, constant: 0),
            ])
//            checkboxStackContainerTopConstraint.constant = 20
            checkboxStackContainer.alignment = .trailing
        default:
            NSLayoutConstraint.activate([
                labelsStackContainer.topAnchor.constraint(equalTo: contentContainerView.topAnchor, constant: 0),
            ])
            checkBoxContainerView.isHidden = true
        }
    }
    
//    func setCheckmarkPosition(_ position: CheckmarkPosition) {
//        
//        switch position {
//        case .left:
//            checkboxStackContainerTopConstraint.constant = 20
//            checkboxStackContainer.alignment = .leading
//        case .center:
//            checkboxStackContainerTopConstraint.constant = 30
//            checkboxStackContainer.alignment = .center
//        }
//    }
    
    func setupCheckBoxSizes(subscriptionItem: ItemTypeSubscription) {
        checkBoxHeight.constant = subscriptionItem.checkBox.styles.width ?? 24
        checkBoxWidth.constant = subscriptionItem.checkBox.styles.height ?? 24
        checkBoxTrailing.constant = subscriptionItem.checkBox.box.styles.paddingRight ?? 0
        checkBoxLeading.constant = subscriptionItem.checkBox.box.styles.paddingLeft ?? 0
        checkBoxTop.constant = subscriptionItem.checkBox.box.styles.paddingTop ?? 0
        checkBoxBot.constant = subscriptionItem.checkBox.box.styles.paddingBottom ?? 0
    }
    
    func setupBadge() {
        savedMoneyView.clipsToBounds = true
        NSLayoutConstraint.activate([
            savedMoneyView.label.topAnchor.constraint(equalTo: savedMoneyView.topAnchor, constant: 0),
            savedMoneyView.label.bottomAnchor.constraint(equalTo: savedMoneyView.bottomAnchor, constant: 0),
            savedMoneyView.label.leadingAnchor.constraint(equalTo: savedMoneyView.leadingAnchor, constant: 0),
            savedMoneyView.label.trailingAnchor.constraint(equalTo: savedMoneyView.trailingAnchor, constant: 0),
        ])
        
        savedMoneyView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(savedMoneyView)
    }
}

// MARK: - Open methods
extension PaywallTileSubscriptionCell {
    enum SavedMoneyBadgePosition {
        case none, left, center, right
    }
    
    enum CheckmarkPosition {
        case left, center
    }
}
