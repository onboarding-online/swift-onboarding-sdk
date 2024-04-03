//
//  StoryboardExampleViewController.swift
//
//  Onboarding.online
//  Copyright 2023 Onboarding.online. All rights reserved.
//

import UIKit
import ScreensGraph

final class ScreenCollectionSingleSelectionVC: BaseChildScreenGraphViewController {
    
    static func instantiate(screenData: ScreenTwoColumnSingleSelection) -> ScreenCollectionSingleSelectionVC {
        let twoColumnSingleSelectionVC = ScreenCollectionSingleSelectionVC.storyBoardInstance()
        twoColumnSingleSelectionVC.screenData = screenData

        return twoColumnSingleSelectionVC
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableStackContainerView1: UIView!
    @IBOutlet weak var tableStackContainerView2: UIView!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    private let numberOfCellsInRow: CGFloat = 2
    private var contentAlignment: CollectionContentVerticalAlignment = .center
    
    var screenData: ScreenTwoColumnSingleSelection!
    
    var selectedItem = [Int]()
    
    let cellConfigurator = TextCollectionCellWithBorderConfigurator.init()


    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        setupCollectionView()
        setupLabelsValue()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.async { [weak self] in
            self?.setTopInset()
            self?.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    override func runInitialAnimation() {
        [tableStackContainerView1, tableStackContainerView2].forEach { view in
            view?.clipsToBounds = false
            view?.layer.masksToBounds = false
        }
        OnboardingAnimation.runAnimationOfType(.tableViewCells(style: .fade), in: collectionView)
    }
}
// MARK: - UICollectionViewDataSource
extension ScreenCollectionSingleSelectionVC: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        allSections().count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let section = allSections()[section]
        
        return rowsFor(section: section).count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = allSections()[indexPath.section]
        let row = rowsFor(section: section)[indexPath.row]
        
        switch row {
        case .item(let item):
            let cell = createCellFor(item: item, indexPath: indexPath, collectionView: collectionView, isSelected: false)
            return cell
        case .label(let text):
            let cell = collectionView.dequeueCellOfType(CollectionLabelCell.self, forIndexPath: indexPath)
            cell.setWithText(text)
            
            return cell
        }
    }
    
    
    func createCellFor(item: ItemTypeSelection, indexPath: IndexPath, collectionView: UICollectionView, isSelected: Bool) -> UICollectionViewCell {
        
        switch self.screenData.list.itemType {
        case .tittle:
            let cell = collectionView.dequeueCellOfType(TitleSubtitleMultipleSelectionCollectionCellWithBorder.self, forIndexPath: indexPath)
            cell.setWith(list: screenData.list, item: item, isSelected: isSelected)
            return cell

        case .titleSubtitle:
            let cell = collectionView.dequeueCellOfType(TitleSubtitleMultipleSelectionCollectionCellWithBorder.self, forIndexPath: indexPath)
            cell.setWith(list: screenData.list, item: item, isSelected: isSelected)
            return cell
        case .smallImageTitle:
            let cell = collectionView.dequeueCellOfType(SmallImageTitleCollectionCell.self, forIndexPath: indexPath)
            cell.setWith(list: screenData.list, item: item, isSelected: isSelected)

            return cell
        case .mediumImageTitle:
            let cell = collectionView.dequeueCellOfType(MediumImageTitleCollectionCell.self, forIndexPath: indexPath)
            cell.setWith(list: screenData.list, item: item, isSelected: isSelected)

            return cell
        case .bigImageTitle:
            let cell = collectionView.dequeueCellOfType(CollectionSelectionCell.self, forIndexPath: indexPath)
            cell.setWith(list: screenData.list, item: item, isSelected: isSelected)
            return cell

        case .fullImage:
            let cell = collectionView.dequeueCellOfType(FullImageCollectionCell.self, forIndexPath: indexPath)
            cell.setWith(list: screenData.list, item: item, isSelected: isSelected)

            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate
extension ScreenCollectionSingleSelectionVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = allSections()[indexPath.section]
        let row = rowsFor(section: section)[indexPath.row]
        
        switch row {
        case .item(_):
            let item = screenData.list.items[indexPath.row]
            
            delegate?.onboardingChildScreenUpdate(value: indexPath.row, description: item.title.textByLocale(), logAnalytics: true)
            delegate?.onboardingChildScreenPerform(action: item.action)
        case .label(_):
            break
        }
    }
}

extension ScreenCollectionSingleSelectionVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let section = allSections()[indexPath.section]
        let row = rowsFor(section: section)[indexPath.row]
        switch row {
        case .label(let text):
            let labelHeight = calculateHeightOf(text: text)
            return CGSize(width: collectionView.bounds.width, height: labelHeight)
        case .item(let item):
            let size = calculateCellSizeFor(item: item)
            return size
        }
    }
    
    func calculateCellSizeFor(item: ItemTypeSelection) -> CGSize {
        let size = calculateItemCellSize()
        let width = size.width

        switch self.screenData.list.itemType {
        case .tittle:
            let maxHeight = maxSizeFor(width: width, includeSubtitle: false)

            return CGSize(width: width, height: maxHeight)
        case .titleSubtitle:
            let maxHeight = maxSizeFor(width: width, includeSubtitle: true)
            return CGSize(width: width, height: maxHeight)
        default:
            return size
        }
    }
    
    func maxSizeFor(width: CGFloat, includeSubtitle: Bool)  -> CGFloat {
        var maxHeight: CGFloat = 0.0
        
        for item in screenData.list.items {
            let subtitle = includeSubtitle ? item.subtitle : nil
            
            let height =  cellConfigurator.calculateHeightFor(titleText: item.title, subtitleText: subtitle, containerWidth: width, horizontalInset: 0.0)
            maxHeight = height > maxHeight ? height : maxHeight
        }
        return maxHeight
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let section = allSections()[section]

        switch section {
        case .titleLabels:
            return cellConfigurator.spacingBetweenTitleLabels
        case .items:
            return calculateMinimumItemsLineSpacingForSections() /// Vertical spacing between rows
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let section = allSections()[section]
        switch section {
        case .titleLabels:
            return .zero
        case .items:
            return .zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let section = allSections()[section]
        switch section {
        case .titleLabels:
            return CGSize(width: collectionView.bounds.width, height: .leastNormalMagnitude)
        case .items:
            return CGSize(width: collectionView.bounds.width, height: cellConfigurator.distanceFromTitlesToItems)
        }
    }
}

// MARK: - Private functions
private extension ScreenCollectionSingleSelectionVC {
    func setTopInset() {
        let contentHeight = collectionView.contentSize.height
        let collectionHeight = collectionView.bounds.height
        
        if contentHeight > collectionHeight {
            collectionView.contentInset.top = 0
            return
        }

        switch contentAlignment {
        case .top:
            return
        case .bottom:
            collectionView.contentInset.top = collectionHeight - contentHeight
        case .center:
            collectionView.contentInset.top = (collectionHeight - contentHeight) / 2
        }
    }
    
    func calculateItemCellSize() -> CGSize {
        let width = collectionView.bounds.width
        let spaces = ScreenCollectionConstants.trailingConstraint + ScreenCollectionConstants.trailingConstraint +  (ScreenCollectionConstants.centerGapConstraint)
        let cellWidth = ((width - spaces)  / 2) - ScreenCollectionConstants.magicGapForCellWidthCalculation

        return .init(width: cellWidth, height: cellWidth)
    }
    
    
    func calculateMinimumItemsLineSpacingForSections() -> CGFloat {
        return ScreenCollectionConstants.verticalSpaceBetweenItemsConstraint
    }
    
    func calculateHeightOf(text: Text) -> CGFloat {
        return text.textHeightBy(textWidth: collectionView.bounds.width)
    }
}

// MARK: - Setup methods
private extension ScreenCollectionSingleSelectionVC {
    
    func setup() {
        setupCollectionView()
        setupLabelsValue()
    }
    
    func setupCollectionView() {
        if let alignment = screenData.list.styles.verticalAlignment?.verticalAlignment() {
            contentAlignment = alignment
        }
        
        collectionView.registerCellNibOfType(CollectionSelectionCell.self)
        collectionView.registerCellNibOfType(CollectionLabelCell.self)
        
        collectionView.registerCellNibOfType(SmallImageTitleCollectionCell.self)
        collectionView.registerCellNibOfType(MediumImageTitleCollectionCell.self)
        collectionView.registerCellNibOfType(FullImageCollectionCell.self)
        collectionView.registerCellNibOfType(TitleSubtitleMultipleSelectionCollectionCellWithBorder.self)
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    func setupLabelsValue() {
        titleLabel.apply(text: screenData?.title)
        subtitleLabel.apply(text: screenData?.subtitle)
    }
}

// MARK: - Open methods
extension ScreenCollectionSingleSelectionVC {
    
    enum SectionType {
        case titleLabels
        case items
    }
    
    enum RowType {
        case item(ItemTypeSelection)
        case label(Text)
    }
    
    func allSections() -> [SectionType] {
        var sections: [SectionType] = []
        if !screenData.title.textByLocale().isEmpty ||
            !screenData.subtitle.textByLocale().isEmpty {
            sections.append(.titleLabels)
        }
        
        sections.append(.items)
        return sections
    }
    
    func rowsFor(section: SectionType) -> [RowType] {
        switch section {
        case .titleLabels:
            let texts = [screenData.title, screenData.subtitle].filter({ !$0.textByLocale().isEmpty })
            return texts.map({ RowType.label($0) })
        case .items:
            return screenData.list.items.map({ RowType.item($0) })
        }
    }
}

struct ScreenCollectionConstants {
    static let spacingBetweenTitleLabels: CGFloat = 16
    
    static let distanceFromTitlesToItems: CGFloat = 32
    
    static let leadingConstraint: CGFloat = 0
    static let trailingConstraint: CGFloat = 0
    
    // will be doubled
    static let centerGapConstraint: CGFloat = 4
    
    static let verticalSpaceBetweenItemsConstraint: CGFloat = 9.5
    
    static let magicGapForCellWidthCalculation: CGFloat = 3


}
