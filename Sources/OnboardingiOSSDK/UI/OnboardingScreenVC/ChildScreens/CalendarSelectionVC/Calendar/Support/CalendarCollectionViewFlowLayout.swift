//
//  CustomCollectionViewFlowLayout.swift
//  eBibelot-iOS
//
//
//  Copyright 2023 Onboarding.online on 09.03.2023.
//

import UIKit

final class CalendarCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    fileprivate var daysInWeek = CGFloat(numberOfDaysInWeek)
    fileprivate var spacing: CGFloat = 10
    fileprivate var widthToHeightRatio: CGFloat = 1/1
    

    convenience init(spacing: CGFloat, scrollDirection: UICollectionView.ScrollDirection = .vertical) {
        self.init()
        
        self.spacing = spacing
        self.scrollDirection = scrollDirection
    }
    
    override func prepare() {
        super.prepare()
        
        guard let cv = collectionView else { return }
        
        self.minimumInteritemSpacing = spacing
        self.minimumLineSpacing = spacing

        
        
        if scrollDirection == .vertical {
            
            let cellWidth = (cv.bounds.width - (daysInWeek - 1) * spacing) / daysInWeek
            let cellHeight = cellWidth * widthToHeightRatio
            
            self.itemSize = CGSize(width: cellWidth, height: cellHeight)
        } else {

            let cellHeight = cv.bounds.height - sectionInset.bottom - sectionInset.top - cv.contentInset.bottom - cv.contentInset.top - spacing
            let cellWidth = cellHeight / widthToHeightRatio
            
            self.itemSize = CGSize(width: cellWidth, height: cellHeight)
        }
        
    }
    
}

