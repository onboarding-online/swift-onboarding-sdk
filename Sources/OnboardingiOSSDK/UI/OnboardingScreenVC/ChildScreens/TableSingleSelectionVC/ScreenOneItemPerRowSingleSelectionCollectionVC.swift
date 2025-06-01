//
//  StoryboardExampleViewController.swift
//
//  Onboarding.online
//  Copyright 2023 Onboarding.online. All rights reserved.
//

import UIKit
import ScreensGraph

class ScreenOneItemPerRowSingleSelectionCollectionVC: BaseCollectionChildScreenGraphViewController {
    
    static func instantiate(screenData: ScreenTableSingleSelection, videoPreparationService: VideoPreparationService?, screen: Screen) -> ScreenOneItemPerRowSingleSelectionCollectionVC {
        let tableSingleSelectionVC = ScreenOneItemPerRowSingleSelectionCollectionVC.storyBoardInstance()
        tableSingleSelectionVC.screenData = screenData
        
        tableSingleSelectionVC.videoPreparationService = videoPreparationService
        tableSingleSelectionVC.screen = screen
        tableSingleSelectionVC.media = screenData.media


        return tableSingleSelectionVC
    }
    
    @IBOutlet weak var iconImage: UIImageView!

//    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableStackContainerView1: UIView!
    @IBOutlet weak var tableStackContainerView2: UIView!
    
    private let numberOfCellsInRow: CGFloat = 1
    private var contentAlignment: CollectionContentVerticalAlignment = .center
    
    var screenData: ScreenTableSingleSelection!
    
    var selectedItem = [Int]()
    
    var selectedIndexPath: IndexPath? = nil

    let cellConfigurator = ImageLabelCheckboxMultipleSelectionCollectionCellWithBorderConfigurator.init()


    override func viewDidLoad() {
        super.viewDidLoad()

        setupInitialCellConfig()
        setup()
        cellConfigurator.distanceFromTitlesToItems = screenData.list.box.styles.paddingTop ?? 0.0
        cellConfigurator.currentItem = screenData.list.items.first

        setupCollectionView()
        setupCollectionConstraintsWith(box: screenData.list.box.styles)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async { [weak self] in
            self?.setTopInset()
            self?.collectionView.collectionViewLayout.invalidateLayout()
            
            if self?.selectedIndexPath != nil {
                self?.setSelectedIndexPath(nil)
            }
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
extension ScreenOneItemPerRowSingleSelectionCollectionVC: UICollectionViewDataSource {
    
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
            let cell = collectionView.dequeueCellOfType(ImageLabelCheckboxMultipleSelectionCollectionCellWithBorderFlexiblePaddings.self, forIndexPath: indexPath)
            cell.cellConfig = cellConfigurator
            UIView.performWithoutAnimation {
                cell.setWith(
                    list: screenData.list,
                    item: item,
                    styles: screenData.list.styles,
                    isSelected: indexPath == selectedIndexPath,
                    useLocalAssetsIfAvailable: useLocalAssetsIfAvailable
                )
            }
            return cell
        case .label(let text):
            
            let cell = collectionView.dequeueCellOfType(CollectionLabelCell.self, forIndexPath: indexPath)
            cell.setWithText(text)
            
            return cell
        }
    }
    
}

// MARK: - UICollectionViewDelegate
extension ScreenOneItemPerRowSingleSelectionCollectionVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = allSections()[indexPath.section]
        let row = rowsFor(section: section)[indexPath.row]
        
        switch row {
        case .item(_):
            if selectedIndexPath != indexPath {
                let item = screenData.list.items[indexPath.row]
                setSelectedIndexPath(indexPath)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    self?.delegate?.onboardingChildScreenUpdate(value: indexPath.row, description: item.title.textByLocale(), logAnalytics: true)
                    self?.delegate?.onboardingChildScreenPerform(action: item.action)
                }
            } else {
                break
            }
        case .label(_):
            break
        }
    }

    func setSelectedIndexPath(_ indexPath: IndexPath?) {
        selectedIndexPath = indexPath
        collectionView.reloadData()
    }
}

extension ScreenOneItemPerRowSingleSelectionCollectionVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let section = allSections()[indexPath.section]
        let row = rowsFor(section: section)[indexPath.row]
        switch row {
        case .label(let text):
            let labelHeight = calculateHeightOf(text: text)
            return CGSize(width: collectionView.bounds.width, height: labelHeight)
        case .item(let item):
            let itemHeight = calculateHeight(item: item, indexPath: indexPath)

            return CGSize(width: collectionView.bounds.width, height: itemHeight)
        }
    }
    
    func calculateHeight(item: ItemTypeSelection, indexPath: IndexPath) -> CGFloat {
        if screenData.list.styles.useMaxCellHeight ?? false {
            let itemHeight = maxSizeFor(width: collectionView.bounds.width, includeSubtitle: true)
            return itemHeight
        } else {
            let index = indexPath.row

            let isSelected = selectedItem.contains(index)
            
            let itemHeight = cellConfigurator.calculateHeightFor1(titleText: item.title,
                                                                  subtitleText: item.subtitle,
                                                                  itemType: screenData.list.itemType,
                                                                  containerWidth: collectionView.bounds.width,
                                                                  horizontalInset: 0, isSelected: isSelected)
            return itemHeight
        }
    }
    
    func maxSizeFor(width: CGFloat, includeSubtitle: Bool)  -> CGFloat {
        var maxHeight: CGFloat = 0.0
        
        for item in screenData.list.items {
            let subtitle = includeSubtitle ? item.subtitle : nil
            
            let height =  cellConfigurator.calculateHeightFor1(titleText: item.title, subtitleText: subtitle, itemType: screenData.list.itemType, containerWidth: width, horizontalInset: 0.0)
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
            return cellConfigurator.spacingBetweenItems
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
private extension ScreenOneItemPerRowSingleSelectionCollectionVC {
    
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
private extension ScreenOneItemPerRowSingleSelectionCollectionVC {
    var useLocalAssetsIfAvailable: Bool { screenData?.useLocalAssetsIfAvailable ?? true }
    
    func setup() {
        setupCollectionView()
    }
    
    func setupCollectionView() {
        if let alignment = screenData.list.styles.verticalAlignment?.verticalAlignment() {
            contentAlignment = alignment
        }
        collectionView.registerCellNibOfType(ImageLabelCheckboxMultipleSelectionCollectionCellWithBorderFlexiblePaddings.self)
        collectionView.registerCellNibOfType(CollectionLabelCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    func setupInitialCellConfig() {
        let box = screenData.list.styles
        cellConfigurator.setupItemsConstraintsWith(box: box)
        cellConfigurator.setupImage(settings: screenData.list.items.first?.image.styles)
    }
    
}

// MARK: - Open methods
extension ScreenOneItemPerRowSingleSelectionCollectionVC {
    
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



