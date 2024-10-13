//
//  StoryboardExampleViewController.swift
//
//  Onboarding.online
//  Copyright 2023 Onboarding.online. All rights reserved.
//

import UIKit
import ScreensGraph


class ScreenImageTitleSubtitleMultiSelectionListVC: BaseChildScreenGraphViewController {
    
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableStackContainerView1: UIView!
    @IBOutlet weak var tableStackContainerView2: UIView!
    
    private let numberOfCellsInRow: CGFloat = 1
    private var contentAlignment: CollectionContentVerticalAlignment = .bottom
    
    var screenData: ScreenImageTitleSubtitleMultipleSelectionList!

    var selectedItem = [Int]()
    
    let cellConfigurator = ImageLabelCheckboxMultipleSelectionCollectionCellNoBorderConfigurator.init()
    
    static func instantiate(screenData: ScreenImageTitleSubtitleMultipleSelectionList) -> ScreenImageTitleSubtitleMultiSelectionListVC {
        let imageTitleSubtitleMultipleSelectionListVC = ScreenImageTitleSubtitleMultiSelectionListVC.storyBoardInstance()
        imageTitleSubtitleMultipleSelectionListVC.screenData = screenData
        
        return imageTitleSubtitleMultipleSelectionListVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupInitialCellConfig()
        setup()
        cellConfigurator.distanceFromTitlesToItems = screenData.list.box.styles.paddingTop ?? 0.0
        setupCollectionView()
        setupLabelsValue()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.delegate?.onboardingChildScreenUpdate(value: selectedItem, description: nil, logAnalytics: false)

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
extension ScreenImageTitleSubtitleMultiSelectionListVC: UICollectionViewDataSource {
    
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
            let cell = collectionView.dequeueCellOfType(ImageLabelCheckboxMultipleSelectionCollectionCellNoBorder.self, forIndexPath: indexPath)
            cell.cellConfig = cellConfigurator

            let index = indexPath.row
            let isSelected =  selectedItem.contains(index)
                
            cell.setWith(list: screenData.list, item: item, isSelected: isSelected,
                         useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
            return cell
        case .label(let text):
            let cell = collectionView.dequeueCellOfType(CollectionLabelCell.self, forIndexPath: indexPath)
            cell.setWithText(text)
            
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate
extension ScreenImageTitleSubtitleMultiSelectionListVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = allSections()[indexPath.section]
        let row = rowsFor(section: section)[indexPath.row]
        var itemTitle: String? = nil

        switch row {
        case .item(let item):
            let index = indexPath.row
            
            if selectedItem.contains(index) {
                selectedItem.removeObject(object: index)
            } else {
                selectedItem.append(index)
            }
            
            itemTitle = item.title.textByLocale()


            if #available(iOS 15.0, *) {
                collectionView.reconfigureItems(at: [indexPath])
            } else {
                collectionView.reloadItems(at: [indexPath])
            }
            self.delegate?.onboardingChildScreenUpdate(value: selectedItem, description: itemTitle, logAnalytics: true)

        case .label(_):
            break
        }
    }
    
}

extension ScreenImageTitleSubtitleMultiSelectionListVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let section = allSections()[indexPath.section]
        let row = rowsFor(section: section)[indexPath.row]
        switch row {
        case .label(let text):
            let labelHeight = calculateHeightOf(text: text)
            return CGSize(width: collectionView.bounds.width, height: labelHeight)
        case .item(let item):
            let itemHeight = cellConfigurator.calculateHeightFor(titleText: item.title,
                                                                  subtitleText: item.subtitle,
                                                                  itemType: screenData.list.itemType,
                                                                  containerWidth: collectionView.bounds.width,
                                                                  horizontalInset: 0)
            return CGSize(width: collectionView.bounds.width, height: itemHeight)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let section = allSections()[section]

        switch section {
        case .titleLabels:
            return cellConfigurator.spacingBetweenTitleLabels
        case .items:
            return cellConfigurator.spacingBetweenItems
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let section = allSections()[section]
        switch section {
        case .titleLabels:
            return .init(top: 0, left: 0.0, bottom: 0, right: 0)
        case .items:
            return .init(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let section = allSections()[section]
        switch section {
        case .titleLabels:
            return CGSize(width: collectionView.bounds.width,
                          height: .leastNormalMagnitude)
        case .items:
            return CGSize(width: collectionView.bounds.width,
                          height: cellConfigurator.distanceFromTitlesToItems)
        }
    }
    
}

// MARK: - Private functions
private extension ScreenImageTitleSubtitleMultiSelectionListVC {
    
    func calculateHeightOf(text: Text) -> CGFloat {
        let textPaddings =  (text.box.styles.paddingLeft ?? 0.0) + (text.box.styles.paddingRight ?? 0.0)
        let rowHeight = text.textHeightBy(textWidth: collectionView.bounds.width - textPaddings)
        
        let texVerticalPaddings =  (text.box.styles.paddingTop ?? 0.0) + (text.box.styles.paddingBottom ?? 0.0)
        
        let fullHeight = rowHeight + texVerticalPaddings
        
        return fullHeight
    }
    
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
    
}

// MARK: - Setup methods
private extension ScreenImageTitleSubtitleMultiSelectionListVC {
    var useLocalAssetsIfAvailable: Bool { screenData?.useLocalAssetsIfAvailable ?? true }
    
    func setup() {
        setupCollectionView()
        setupLabelsValue()
        setupImageContentMode()
    }
    
    func setupCollectionView() {
        if let alignment = screenData.list.styles.verticalAlignment?.verticalAlignment() {
            contentAlignment = alignment
        }
        collectionView.registerCellNibOfType(ImageLabelCheckboxMultipleSelectionCollectionCellNoBorder.self)
        collectionView.registerCellNibOfType(CollectionLabelCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    func setupLabelsValue() {
        load(image: screenData.image, in: iconImage,
             useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
    }
    
    func setupImageContentMode() {
        if let imageContentMode = screenData.image.imageContentMode() {
            iconImage.contentMode = imageContentMode
        } else {
            iconImage.contentMode = .scaleAspectFit
        }
    }
    
    func setupInitialCellConfig() {
        let box = screenData.list.styles
        cellConfigurator.setupItemsConstraintsWith(box: box)
        cellConfigurator.setupImage(settings: screenData.list.items.first?.image.styles)
        cellConfigurator.checkboxSize = 16.0
    }
    
}

// MARK: - Open methods
extension ScreenImageTitleSubtitleMultiSelectionListVC {
    
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
