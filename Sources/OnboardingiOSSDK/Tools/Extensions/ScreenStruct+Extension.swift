//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 06.04.2024.
//

import Foundation
import ScreensGraph

extension ScreenStruct {
    var useLocalAssetsIfAvailable: Bool {
        switch self {
        case .typeCustomScreen(let screen):
            return screen.useLocalAssetsIfAvailable
        case .typeScreenBasicPaywall(let screen):
            return screen.useLocalAssetsIfAvailable
        case .typeScreenImageTitleSubtitleList(let screen):
            return screen.useLocalAssetsIfAvailable
        case .typeScreenImageTitleSubtitleMultipleSelectionList(let screen):
            return screen.useLocalAssetsIfAvailable
        case .typeScreenImageTitleSubtitlePicker(let screen):
            return screen.useLocalAssetsIfAvailable
        case .typeScreenImageTitleSubtitles(let screen):
            return screen.useLocalAssetsIfAvailable
        case .typeScreenProgressBarTitle(let screen):
            return screen.useLocalAssetsIfAvailable
        case .typeScreenSlider(let screen):
            return screen.useLocalAssetsIfAvailable
        case .typeScreenTableMultipleSelection(let screen):
            return screen.useLocalAssetsIfAvailable
        case .typeScreenTableSingleSelection(let screen):
            return screen.useLocalAssetsIfAvailable
        case .typeScreenTitleSubtitleCalendar(let screen):
            return screen.useLocalAssetsIfAvailable
        case .typeScreenTitleSubtitleField(let screen):
            return screen.useLocalAssetsIfAvailable
        case .typeScreenTitleSubtitlePicker(let screen):
            return screen.useLocalAssetsIfAvailable
        case .typeScreenTooltipPermissions(let screen):
            return screen.useLocalAssetsIfAvailable
        case .typeScreenTwoColumnMultipleSelection(let screen):
            return screen.useLocalAssetsIfAvailable
        case .typeScreenTwoColumnSingleSelection(let screen):
            return screen.useLocalAssetsIfAvailable
        }
    }
}
