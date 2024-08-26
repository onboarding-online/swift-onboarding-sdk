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
    
    func listValuesFor(indexes: [Int]) -> String {
        switch self {
        case .typeScreenTwoColumnMultipleSelection(let screen):
            let values = screen.list.items.compactMap({$0.title.textByLocale()})
            let value = values[safeIdxs: indexes].joined(separator: ", ")
            return value
        case .typeScreenTwoColumnSingleSelection(let screen):
            let values = screen.list.items.compactMap({$0.title.textByLocale()})
            let value = values[safeIdxs: indexes].joined(separator: ", ")
            return value
        case .typeScreenTableMultipleSelection(let screen):
            let values = screen.list.items.compactMap({$0.title.textByLocale()})
            let value = values[safeIdxs: indexes].joined(separator: ", ")
            return value
        case .typeScreenTableSingleSelection(let screen):
            let values = screen.list.items.compactMap({$0.title.textByLocale()})
            let value = values[safeIdxs: indexes].joined(separator: ", ")
            return value
        case .typeScreenImageTitleSubtitleMultipleSelectionList(let screen):
            let values = screen.list.items.compactMap({$0.title.textByLocale()})
            let value = values[safeIdxs: indexes].joined(separator: ", ")
            return value
        default:
            return ""
        }
    }
}


public extension Collection {
    
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    subscript(safeIdxs idxArr: [Index] ) -> [Element] {
        return idxArr.compactMap{ self[safe: $0] }
    }
    
    subscript(safeIdxs idxArr: CountableClosedRange<Int> ) -> [Element] {
        return idxArr.compactMap{ $0 as? Index }.compactMap{ self[ safe: $0] }
    }
    
    subscript(safeIdxs idxArr: CountableRange<Int> ) -> [Element] {
        return idxArr.compactMap{ $0 as? Index }.compactMap{ self[ safe: $0 ] }
    }
}
