//
//  StoryboardExampleViewController.swift
//
//  Onboarding.online
//  Copyright 2023 Onboarding.online. All rights reserved.
//

import UIKit
import ScreensGraph

class ScreenImageTitleSubtitleBulletsVC: BaseChildScreenGraphViewController {
    
    static func instantiate(screenData: ScreenImageTitleSubtitleList) -> ScreenImageTitleSubtitleBulletsVC {
        let imageTitleSubtitleListVC = ScreenImageTitleSubtitleBulletsVC.storyBoardInstance()
        imageTitleSubtitleListVC.screenData = screenData

        return imageTitleSubtitleListVC
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableStackContainerView1: UIView!
    @IBOutlet weak var tableStackContainerView2: UIView!
    @IBOutlet weak var topSpaceConstraint: NSLayoutConstraint!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var iconImage: UIImageView!

    private let numberOfCellsInRow: CGFloat = 1
    private var contentAlignment: CollectionContentVerticalAlignment = .center
    
    var screenData: ScreenImageTitleSubtitleList!

    let cellConfigurator = BulletsImageLabelCollectionCellConfigurator.init()

    var selectedItem = [Int]()

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
        OnboardingAnimation.runAnimationOfType(.tableViewCells(style: .move), in: collectionView)
    }
}
// MARK: - UICollectionViewDataSource
extension ScreenImageTitleSubtitleBulletsVC: UICollectionViewDataSource {
    
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
            let cell = collectionView.dequeueCellOfType(BulletsImageLabelCollectionCell.self, forIndexPath: indexPath)
            cell.cellConfig = cellConfigurator
            
            cell.setWith(listType: screenData.list.itemType, item: item, styles: screenData.list.styles, isSelected: true,
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
extension ScreenImageTitleSubtitleBulletsVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) { }
    
}

extension ScreenImageTitleSubtitleBulletsVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let section = allSections()[indexPath.section]
        let row = rowsFor(section: section)[indexPath.row]
        switch row {
        case .label(let text):
            let labelHeight = text.textHeightBy(textWidth: collectionView.bounds.width)
            return CGSize(width: collectionView.bounds.width, height: labelHeight)
        case .item(let item):
            let itemHeight = cellConfigurator.calculateHeightFor(titleText: item.title,
                                                                  subtitleText: nil,
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
            return .zero
        case .items:
            return .init(top: 0, left: 0, bottom: 0, right: 0)
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
private extension ScreenImageTitleSubtitleBulletsVC {
    
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
    
    func calculateHorizontalInset() -> CGFloat {
        return 0
    }
    
}

// MARK: - Setup methods
private extension ScreenImageTitleSubtitleBulletsVC {
    var useLocalAssetsIfAvailable: Bool { screenData?.useLocalAssetsIfAvailable ?? true }
    
    func setup() {
        setupCollectionView()
        setupLabelsValue()
        setupImageContentMode()
    }
    
    func setupCollectionView() {
        let box = screenData.list.styles
        cellConfigurator.setupItemsConstraintsWith(box: box)
        cellConfigurator.setupImage(settings: screenData.list.items.first?.image.styles)
        
        if let alignment = screenData.list.styles.verticalAlignment?.verticalAlignment() {
            contentAlignment = alignment
        }
        
        collectionView.registerCellNibOfType(BulletsImageLabelCollectionCell.self)
        collectionView.registerCellNibOfType(CollectionLabelCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.clipsToBounds = true
        collectionView.layer.masksToBounds = true
       
        // Calculated top constraint for image
        topSpaceConstraint.constant = UIScreen.main.bounds.height * 0.07
    }
    
    func setupLabelsValue() {
        load(image: screenData.image, in: iconImage, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
        titleLabel.apply(text: screenData.title)
    }
    
    func setupImageContentMode() {
        if let imageContentMode = screenData.image.imageContentMode() {
            iconImage.contentMode = imageContentMode
        } else {
            iconImage.contentMode = .scaleAspectFit
        }
    }
}

// MARK: - Open methods
extension ScreenImageTitleSubtitleBulletsVC {
    enum SectionType {
        case titleLabels
        case items
    }
    
    enum RowType {
        case item(ItemTypeRegular)
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
            let texts = [screenData.subtitle].filter({ !$0.textByLocale().isEmpty })
            return texts.map({ RowType.label($0) })
        case .items:
            return screenData.list.items.map({ RowType.item($0) })
        }
    }
}
