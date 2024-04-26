//
//  StoryboardExampleViewController.swift
//
//  Onboarding.online
//  Copyright 2023 Onboarding.online. All rights reserved.
//

import UIKit
import ScreensGraph


class ScreenImageTitleForNotificationVC: BaseChildScreenGraphViewController {
    
    static func instantiate(screenData: ScreenTooltipPermissions) -> ScreenImageTitleForNotificationVC {
        let tooltipPermissionsVC = ScreenImageTitleForNotificationVC.storyBoardInstance()
        tooltipPermissionsVC.screenData = screenData
        return tooltipPermissionsVC
    }
    
    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var pageImage: UIImageView!
        
    var screenData: ScreenTooltipPermissions!

    override func viewDidLoad() {
        super.viewDidLoad()
                
        setupImage()
        setupLabelsValue()
    }
    
    func setupImage() {
        load(image: screenData.tooltip.image, in: pageImage,
             useLocalAssetsIfAvailable: screenData?.useLocalAssetsIfAvailable ?? true)
    }
    
    func setupLabelsValue() {
        titleLabel.apply(text: screenData?.tooltip.title)
    }
    
}


