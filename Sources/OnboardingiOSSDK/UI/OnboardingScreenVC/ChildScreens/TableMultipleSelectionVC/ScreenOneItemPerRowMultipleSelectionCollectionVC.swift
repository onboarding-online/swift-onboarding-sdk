//
//  StoryboardExampleViewController.swift
//
//  Onboarding.online
//  Copyright 2023 Onboarding.online. All rights reserved.
//

import UIKit
import ScreensGraph


class ScreenOneItemPerRowMultipleSelectionCollectionVC: BaseCollectionChildScreenGraphViewController {
    
    static func instantiate(screenData: ScreenTableMultipleSelection, videoPreparationService: VideoPreparationService?, screen: Screen) -> ScreenOneItemPerRowMultipleSelectionCollectionVC {
        let tableMultipleSelectionVC = ScreenOneItemPerRowMultipleSelectionCollectionVC.storyBoardInstance()
        tableMultipleSelectionVC.screenData = screenData
        
        tableMultipleSelectionVC.videoPreparationService = videoPreparationService
        tableMultipleSelectionVC.screen = screen
        tableMultipleSelectionVC.media = screenData.media

        
        return tableMultipleSelectionVC
    }
    
    @IBOutlet weak var iconImage: UIImageView!

//    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableStackContainerView1: UIView!
    @IBOutlet weak var tableStackContainerView2: UIView!
    

    private let numberOfCellsInRow: CGFloat = 1
    private var contentAlignment: CollectionContentVerticalAlignment = .center
    
    var screenData: ScreenTableMultipleSelection!

    var selectedItem = [Int]()
    
    let cellConfigurator = ImageLabelCheckboxMultipleSelectionCollectionCellWithBorderConfigurator.init()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        setupCollectionView()
        
        setupCollectionConstraintsWith(box: screenData.list.box.styles)
        
        cellConfigurator.setupItemsConstraintsWith(box: screenData.list.styles)
        cellConfigurator.setupImage(settings: screenData.list.items.first?.image.styles)
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
extension ScreenOneItemPerRowMultipleSelectionCollectionVC: UICollectionViewDataSource {
    
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
            let cell = collectionView.dequeueCellOfType(ImageLabelCheckboxMultipleSelectionCollectionCellWithBorder.self, forIndexPath: indexPath)
            cell.cellConfig = cellConfigurator
            let isSelected =  selectedItem.contains(indexPath.row)
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
extension ScreenOneItemPerRowMultipleSelectionCollectionVC: UICollectionViewDelegate {
    
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
            self.delegate?.onboardingChildScreenUpdate(value: selectedItem, description: itemTitle,logAnalytics: true)
        case .label(_):
            break
        }
    }
}

extension ScreenOneItemPerRowMultipleSelectionCollectionVC: UICollectionViewDelegateFlowLayout {
  
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let section = allSections()[indexPath.section]
        let row = rowsFor(section: section)[indexPath.row]
        switch row {
        case .label(let text):
            let labelHeight = calculateHeightOf(text: text)
            return CGSize(width: collectionView.bounds.width, height: labelHeight)
        case .item(let item):
            let itemHeight = calculateHeight(item: item)
            
            return CGSize(width: collectionView.bounds.width, height: itemHeight)
        }
    }
    
    func calculateHeight(item: ItemTypeSelection) -> CGFloat {
        if screenData.list.styles.useMaxCellHeight ?? false {
            let itemHeight = maxSizeFor(width: collectionView.bounds.width, includeSubtitle: true)
            return itemHeight
        } else {
            let itemHeight = cellConfigurator.calculateHeightFor(titleText: item.title,
                                                                  subtitleText: item.subtitle,
                                                                  itemType: screenData.list.itemType,
                                                                  containerWidth: collectionView.bounds.width,
                                                                  horizontalInset: 0)
            return itemHeight
        }
    }
    
    func maxSizeFor(width: CGFloat, includeSubtitle: Bool)  -> CGFloat {
        var maxHeight: CGFloat = 0.0
        
        for item in screenData.list.items {
            let subtitle = includeSubtitle ? item.subtitle : nil
            
            let height =  cellConfigurator.calculateHeightFor(titleText: item.title, subtitleText: subtitle, itemType: screenData.list.itemType, containerWidth: width, horizontalInset: 0.0)
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
        return .zero
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



// MARK: - Setup methods
private extension ScreenOneItemPerRowMultipleSelectionCollectionVC {
    var useLocalAssetsIfAvailable: Bool { screenData?.useLocalAssetsIfAvailable ?? true }
    func setup() {
        setupCollectionView()
    }
    
    func setupCollectionView() {
        if let alignment = screenData.list.styles.verticalAlignment?.verticalAlignment() {
            contentAlignment = alignment
        }
        collectionView.registerCellNibOfType(ImageLabelCheckboxMultipleSelectionCollectionCellWithBorder.self)
        collectionView.registerCellNibOfType(CollectionLabelCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
}

// MARK: - Open methods
extension ScreenOneItemPerRowMultipleSelectionCollectionVC {
    
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


// MARK: - Private functions
private extension ScreenOneItemPerRowMultipleSelectionCollectionVC {
    
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

    
enum CollectionContentVerticalAlignment {
    case top, bottom, center
}
    
