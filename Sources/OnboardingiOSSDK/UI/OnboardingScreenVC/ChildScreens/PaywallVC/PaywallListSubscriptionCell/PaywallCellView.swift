//
//  File.swift
//  
//
//  Created by Leonid Yuriev on 14.03.24.
//

import Foundation
import UIKit
import ScreensGraph

class PaywallCellView: UIView {
    
    @IBOutlet private weak var contentContainerView: UIView!
    @IBOutlet private weak var mainContainerStack: UIStackView!

    @IBOutlet private weak var checkbox: UIImageView!
    @IBOutlet private weak var checkBoxContainerView: UIView!

    @IBOutlet private weak var leftLabelTop: UILabel!
    @IBOutlet private weak var leftLabelBottom: UILabel!
    
    @IBOutlet private weak var rightLabelTop: UILabel!
    @IBOutlet private weak var rightLabelBottom: UILabel!

    @IBOutlet private weak var contentLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var mainContainerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mainContainerTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mainContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mainContainerBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var cellLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var cellTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var cellTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var cellBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var checkBoxHeight: NSLayoutConstraint!
    @IBOutlet private weak var checkBoxWidth: NSLayoutConstraint!
    
    @IBOutlet private weak var checkBoxLeading: NSLayoutConstraint!
    @IBOutlet private weak var checkBoxTrailing: NSLayoutConstraint!
    @IBOutlet private weak var checkBoxBot: NSLayoutConstraint!
    @IBOutlet private weak var checkBoxTop: NSLayoutConstraint!

    @IBOutlet private weak var containerStack: UIStackView!
    @IBOutlet private weak var leftStack: UIStackView!
    @IBOutlet private weak var rightStack: UIStackView!

    @IBOutlet private weak var savedMoneyView: SavedMoneyView!
    private var currentSavedMoneyViewConstraints: [NSLayoutConstraint] = []
    
    private var item: ItemTypeSubscription? = nil
    private var list: SubscriptionList? = nil
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    // Инициализатор, который вызывается при создании вью из XIB
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        clipsToBounds = false
        savedMoneyView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    
    
}


// MARK: - Open methods
extension PaywallCellView {
    
    func setWith(isSelected: Bool,
                 subscriptionItem: ItemTypeSubscription,
                 listWithStyles: SubscriptionList,
                 product: StoreKitProduct) {
        
        checkbox.apply(checkbox: subscriptionItem.checkBox, isSelected: isSelected)
        
        self.item = subscriptionItem
        self.list = listWithStyles
        setBadgePosition(settings: subscriptionItem.badge)
        setSelected(isSelected, listWithStyles: listWithStyles)
        
        setupLabels(subscriptionItem: subscriptionItem, product: product)
        setupCheckboxWith(list: listWithStyles)
        
        if let item = item, let list = list {
            self.layoutSubviews()
            setupSizes(subscriptionItem: item, list: list)
        }
    }
    
    func setupCheckboxWith(list: SubscriptionList) {
        switch list.itemType {
        case .checkboxLabels:
            break
        case .labelsCheckbox:
            checkBoxContainerView.removeFromSuperview()
            mainContainerStack.insertArrangedSubview(checkBoxContainerView, at: 1)
        default:
            checkBoxContainerView.isHidden = true
        }
        mainContainerStack.setNeedsLayout()
        mainContainerStack.layoutIfNeeded()
    }
    
    func setupLabels(subscriptionItem: ItemTypeSubscription, product: StoreKitProduct) {
        leftLabelTop.apply(text: subscriptionItem.leftLabelTop)
        leftLabelBottom.apply(text: subscriptionItem.leftLabelBottom)
        rightLabelTop.apply(text: subscriptionItem.rightLabelTop)
        rightLabelBottom.apply(text: subscriptionItem.rightLabelBottom)

//        leftLabelTop.text =  subscriptionItem.leftLabelTop.textFor(product: product)
//        leftLabelBottom.text = subscriptionItem.leftLabelBottom.textFor(product: product)
//        rightLabelTop.text = subscriptionItem.rightLabelTop.textFor(product: product)
//        rightLabelBottom.text = subscriptionItem.rightLabelBottom.textFor(product: product)
    }

}

// MARK: - Private methods
private extension PaywallCellView {
    
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
            NSLayoutConstraint.deactivate(currentSavedMoneyViewConstraints)

            var constraints: [NSLayoutConstraint] = [savedMoneyView.heightAnchor.constraint(equalToConstant: 24),
                                                     savedMoneyView.centerYAnchor.constraint(equalTo: topAnchor)]
            savedMoneyView.isHidden = false
            
            savedMoneyView.backgroundColor = badge.styles.backgroundColor?.hexStringToColor ?? UIColor.clear
            
            savedMoneyView.layer.borderWidth = badge.styles.borderWidth ?? 0
            savedMoneyView.layer.cornerRadius = badge.styles.borderRadius ?? 0
            savedMoneyView.layer.borderColor = badge.styles.borderColor?.hexStringToColor.cgColor ?? UIColor.clear.cgColor

            savedMoneyView.label.apply(badge: settings)
            switch badge.styles.position {
            case .topleft:
                constraints.append(savedMoneyView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: 16))
            case .topcenter:
                constraints.append(savedMoneyView.centerXAnchor.constraint(equalTo: centerXAnchor))
            case .topright:
                constraints.append(contentContainerView.trailingAnchor.constraint(equalTo: savedMoneyView.trailingAnchor, constant: 16))
            default:
                constraints.append(savedMoneyView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: 16))
            }
            NSLayoutConstraint.activate(constraints)
            currentSavedMoneyViewConstraints = constraints
        } else {
            savedMoneyView.isHidden = true
        }
    }
    
}

// MARK: - Open methods
extension PaywallCellView {
    
    func setupSizes(subscriptionItem: ItemTypeSubscription, list: SubscriptionList) {

        setupCheckBoxSizes(subscriptionItem: subscriptionItem)
        
        mainContainerBottomConstraint.constant = list.styles.paddingBottom ?? 16
        mainContainerTopConstraint.constant = list.styles.paddingTop ?? 16
        mainContainerTrailingConstraint.constant = list.styles.paddingRight ?? 16
        mainContainerLeadingConstraint.constant = list.styles.paddingLeft ?? 16

        cellLeadingConstraint.constant = 16 + (list.box.styles.paddingLeft ?? 0)
        cellTrailingConstraint.constant = 16 + (list.box.styles.paddingRight ?? 0)
        
        let horizontalSpacing = subscriptionItem.styles.columnHorizontalPadding ?? 4
        
        let leftColumnSize = ((subscriptionItem.styles.leftLabelColumnWidthPercentage ?? 60)/100.00)
        let rightColumnSize = 1 - leftColumnSize
        let multiplier = leftColumnSize / rightColumnSize

        leftStack.translatesAutoresizingMaskIntoConstraints = false
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        containerStack.translatesAutoresizingMaskIntoConstraints = false

        leftStack.spacing = subscriptionItem.styles.columnVerticalPadding ?? 4
        rightStack.spacing = subscriptionItem.styles.columnVerticalPadding ?? 4
        
        leftStack.setContentHuggingPriority(UILayoutPriority(250), for: .horizontal) // Для вертикального стека
        leftStack.setContentCompressionResistancePriority(UILayoutPriority(750), for: .horizontal) // Для вертикального стека
        
        rightStack.setContentHuggingPriority(UILayoutPriority(250), for: .horizontal) // Для вертикального стека
        rightStack.setContentCompressionResistancePriority(UILayoutPriority(750), for: .horizontal) // Для вертикального стека

        
        let labels = [leftLabelTop, leftLabelBottom, rightLabelTop, rightLabelBottom]

        for label in labels {
            if let label = label {
                // Настройка для поддержания размера контента по вертикали
                
                label.setContentHuggingPriority(UILayoutPriority(250), for: .vertical) // Для вертикального стека
                label.setContentCompressionResistancePriority(UILayoutPriority(750), for: .vertical) // Для вертикального стека
  
                label.setContentHuggingPriority(UILayoutPriority(250), for: .horizontal) // Для вертикального стека
                label.setContentCompressionResistancePriority(UILayoutPriority(750), for: .horizontal) // Для вертикального стека
                

                // Установка количества строк на 0 позволяет лейблу поддерживать многострочный текст.
                label.numberOfLines = 0
            }
        }
        
        if !subscriptionItem.isOneColumn() {
            containerStack.spacing = horizontalSpacing
            (leftStack.widthAnchor.constraint(equalTo: rightStack.widthAnchor, multiplier: multiplier)).isActive = true
        }
    }
    
    func setupCheckBoxSizes(subscriptionItem: ItemTypeSubscription) {
        checkBoxHeight.constant = subscriptionItem.checkBox.styles.width ?? 24
        checkBoxWidth.constant = subscriptionItem.checkBox.styles.height ?? 24
        checkBoxTrailing.constant = subscriptionItem.checkBox.box.styles.paddingRight ?? 0
        checkBoxLeading.constant = subscriptionItem.checkBox.box.styles.paddingLeft ?? 0
        checkBoxTop.constant = subscriptionItem.checkBox.box.styles.paddingTop ?? 0
        checkBoxBot.constant = subscriptionItem.checkBox.box.styles.paddingBottom ?? 0
    }
    
    enum SavedMoneyBadgePosition {
        case none, left, center, right
    }
}
