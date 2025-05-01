//
//  OboardingsModelExtentionsTemp.swift
//  OnboardingOnline
//
//  Created by Leonid Yuriev on 16.02.23.
//

import Foundation
import UIKit
import ScreensGraph
import AVFoundation

extension ScreensGraph {
    
    func onboardingId() ->  String {
        if let onboardingId = self.metadata["onboardingId"] {
            return onboardingId
        }
        return ""
    }
    
    func onboardingName() ->  String {
        if let onboardingName = self.metadata["onboardingName"] {
            return onboardingName
        }
        return ""
    }
    
    func projectId() ->  String {
        if let projectId = self.metadata["projectId"] {
            return projectId
        }
        return ""
    }
    
    func projectName() ->  String {
        if let projectName = self.metadata["projectName"] {
            return projectName
        }
        return ""
    }
    
    func screenGraphAnalyticsParams() -> AnalyticsEventParameters  {
        let params: AnalyticsEventParameters = [.projectId: projectId(), .projectName : projectName(), .onboardingId : onboardingId(), .onboardingName :  onboardingName()]
        return params
    }
    
}

final class LocaleHelper {
    
    static func filteredLanguagesFor(anyDict: [String: Any]) -> [String: Any] {
        var filteredDict = anyDict
        if  let supportedLanguages = OnboardingService.shared.screenGraph?.languages.compactMap({$0.rawValue}), let values = Array(anyDict.keys) as? [String] {
            
            let difference = supportedLanguages.difference(from: values)
            for language in difference {
                filteredDict.removeValue(forKey: language)
            }
            
        }
        return filteredDict
    }
    
    static func valueByLocaleFor(anyDict: [String: Any], defaultLanguage: String? = OnboardingService.shared.screenGraph?.defaultLanguage.rawValue) -> Any {
        // Check value for language code + region. Example: en-US
        let filteredDict = filteredLanguagesFor(anyDict: anyDict)
       
        if OnboardingService.shared.prefersLanguageOverRegion {
            let preferredLocalizations = Bundle.main.preferredLocalizations
            for language in preferredLocalizations {
                let lang = language
                if  let value =  filteredDict[lang] {
                    return value
                }
            }
        }
        
        for language in Locale.preferredLanguages {
            let lang = language
            if  let value =  filteredDict[lang] {
                return value
            }
        }
        // Check value for language code: ru
        if let langCode = Locale.current.languageCode {
            if  let value =  filteredDict[langCode] {
                return value
            }
        }
        
        // Check value for languge code zh-Hans, zh-Hant
        if let langCode = Locale.current.languageCode , let scriptCode = Locale.current.scriptCode {
            if  langCode == "zh" {
                if scriptCode == "Hans", let value =  filteredDict["zh-Hans"] {
                    return value
                } else if scriptCode == "Hant", let value =  filteredDict["zh-Hant"] {
                    return value
                }
            }
        }

        // Check value for default language code: ru, en-US,...
        if let defaultLanguage = defaultLanguage {
            if  let value =  filteredDict[defaultLanguage] {
                return value
            }
        }
        
        // Get any value to show something
        return anyDict.first?.value ?? ""
    }
    
    
    static func valueByLocaleFor(dict: [String: String], defaultLanguage: String?) -> String {
        
        if let value = LocaleHelper.valueByLocaleFor(anyDict: dict, defaultLanguage: defaultLanguage) as? String {
            return value
        } else {
            return dict.first?.value ?? ""
        }
    }
    
    static func valueByLocaleFor(dict: [String: Asset], defaultLanguage: String?) -> Asset? {
        
        if let value = LocaleHelper.valueByLocaleFor(anyDict: dict, defaultLanguage: defaultLanguage) as? Asset {
            return value
        } else {
            return dict.first?.value
        }
    }
}

protocol OnboardingLocalAssetProvider {
    var l10n: [String: Asset] { get } /* Dictionary of localized Asset */
    func assetUrlByLocale() -> Asset?
}

extension OnboardingLocalAssetProvider {
    func assetUrlByLocale() -> Asset? {
        let defaultLanguage = OnboardingService.shared.screenGraph?.defaultLanguage.rawValue
        let valueByLocale = LocaleHelper.valueByLocaleFor(dict: l10n,
                                                          defaultLanguage: defaultLanguage)
        
        return valueByLocale
    }
}
protocol OnboardingLocalVideoAssetProvider: OnboardingLocalAssetProvider { }



extension CurrencyFormatKind {
    
    func formatStyle() -> NumberFormatter.Style {
        switch self {
        case ._none:
            return NumberFormatter.Style.none
        case .decimal:
            return NumberFormatter.Style.decimal
        case .currency:
            return NumberFormatter.Style.currency
        case .percent:
            return NumberFormatter.Style.percent
        case .scientific:
            return NumberFormatter.Style.scientific
        case .spellOut:
            return NumberFormatter.Style.spellOut
        case .ordinal:
            return NumberFormatter.Style.ordinal
        case .currencyISOCode:
            return NumberFormatter.Style.currencyISOCode
        case .currencyPlural:
            return NumberFormatter.Style.currencyPlural
        case .currencyAccounting:
            return NumberFormatter.Style.currencyAccounting
        }
    }

}

extension OnboardingLocalVideoAssetProvider {
    
    func urlToVideoAsset(useLocalAssetsIfAvailable: Bool) async -> URL? {
        let urlByLocale = assetUrlByLocale()
        
        if let name = urlByLocale?.assetName {
            if let videoURL = Bundle.main.url(forResource: name, withExtension: "mp4") {
                return videoURL
            }
        }
        
        guard let stringURL = urlByLocale?.assetUrl?.origin else {
            return nil
        }
        
        if !useLocalAssetsIfAvailable {
            let _ = await AssetsLoadingService.shared.loadData(from: stringURL, assetType: .video)
            if let storedURL = AssetsLoadingService.shared.urlToStoredData(from: stringURL, assetType: .video) {
                return storedURL
            }
        }
        
        if let cachedURL = getCachedURLToVideoAsset() {
            return cachedURL
        }
        
        let _ = await AssetsLoadingService.shared.loadData(from: stringURL, assetType: .video)
        if let storedURL = AssetsLoadingService.shared.urlToStoredData(from: stringURL, assetType: .video) {
            return storedURL
        } else if let url = URL(string: stringURL) {
            return url
        }
        return nil
    }
    
    func getCachedURLToVideoAsset() -> URL? {
        guard let urlByLocale = assetUrlByLocale(),
              let stringURL = urlByLocale.assetUrl?.origin else { return nil }
       
        if let name = urlByLocale.assetName,
           let videoURL = Bundle.main.url(forResource: name, withExtension: "mp4") {
            return videoURL
        }
        
        if let name = stringURL.resourceNameWithoutExtension(),
           let videoURL = Bundle.main.url(forResource: name, withExtension: "mp4") {
            return videoURL
        }
        
        if let name = stringURL.resourceName(),
           let videoURL = Bundle.main.url(forResource: name, withExtension: nil) {
            return videoURL
        }
        
        return AssetsLoadingService.shared.urlToStoredData(from: stringURL, assetType: .video)
    }
}

extension BaseVideo: OnboardingLocalVideoAssetProvider { }

protocol OnboardingLocalImageAssetProvider: OnboardingLocalAssetProvider { }

extension OnboardingLocalImageAssetProvider {
    
    func loadImage(useLocalAssetsIfAvailable: Bool) async -> UIImage? {
        let urlByLocale = assetUrlByLocale()
        
        if !useLocalAssetsIfAvailable,
           let url = urlByLocale?.assetUrl?.origin {
            return await AssetsLoadingService.shared.loadImage(from: url)
        }
        
        if let assetName = urlByLocale?.assetName,
           let image = getLocalImageWith(assetName: assetName) {
            return image
        } else if let url = urlByLocale?.assetUrl?.origin {
            // Check local resources first
            if let cachedImage = AssetsLoadingService.shared.getCachedImageWith(name: url) {
                return cachedImage
            } else if let image = await getLocalImageWith(assetURL: url) {
                return image
            }
            
            return await AssetsLoadingService.shared.loadImage(from: url)
        }
        return nil
    }
    
    func loadCashedImage(useLocalAssetsIfAvailable: Bool)  -> UIImage? {
        let urlByLocale = assetUrlByLocale()
        
        if let url = urlByLocale?.assetUrl?.origin, 
            let cachedImage = AssetsLoadingService.shared.getCachedImageWith(name: url) {
            return cachedImage
        } else  {
            return nil
        }
    }
    
    private func getLocalImageWith(assetName: String) -> UIImage? {
        if let cachedImage = AssetsLoadingService.shared.getCachedImageWith(name: assetName) {
            return cachedImage
        } else if let image = UIImage.init(named: assetName) {
            Task {
                await AssetsLoadingService.shared.cacheImage(image, withName: assetName)
            }
            return image
        }
        return nil
    }
    
    private func getLocalImageWith(assetURL: String) async -> UIImage? {
        if let imageName = assetURL.resourceName(),
           let image = await UIImage.createWith(name: imageName) {
            AssetsLoadingService.shared.cacheImage(image, withName: assetURL)
            return image
        }
        return nil
    }

}

extension Image: OnboardingLocalImageAssetProvider {

    func imageContentMode() -> UIView.ContentMode? {
        if let scaleMode = styles.scaleMode {
            switch scaleMode {
                
            case .scaletofill:
                return .scaleToFill
            case .scaleaspectfit:
                return .scaleAspectFit
            case .scaleaspectfill:
                return .scaleAspectFill
            case .center:
                return .center
            case .top:
                return .top
            case .bottom:
                return .bottom
            case ._left:
                return .left
            case ._right:
                return .right
            }
        }
        return nil
    }
    
}


extension BaseImage: OnboardingLocalImageAssetProvider { 
    
    func imageContentMode() -> UIView.ContentMode? {
        if let scaleMode = styles.scaleMode {
            switch scaleMode {
                
            case .scaletofill:
                return .scaleToFill
            case .scaleaspectfit:
                return .scaleAspectFit
            case .scaleaspectfill:
                return .scaleAspectFill
            case .center:
                return .center
            case .top:
                return .top
            case .bottom:
                return .bottom
            case ._left:
                return .left
            case ._right:
                return .right
            }
        }
        return nil
    }
    
    
}

extension ScreenBasicPaywall {
   
    func image()-> BaseImage? {
        switch self.media?.content {
        case .typeMediaImage(let image):
            return image.image
        default:
            return nil
        }
    }
    
}

extension Media {
    
    func image()-> BaseImage? {
        switch self.content {
        case .typeMediaImage(let image):
            return image.image
        default:
            return nil
        }
    }
    
    func video()-> BaseVideo? {
        switch self.content {
        case .typeMediaVideo(let image):
            return image.video
        default:
            return nil
        }
    }
    
}

extension MediaScaleMode {
    
    func imageContentMode() -> UIView.ContentMode? {
            switch self {
                
            case .scaletofill:
                return .scaleToFill
            case .scaleaspectfit:
                return .scaleAspectFit
            case .scaleaspectfill:
                return .scaleAspectFill
            case .center:
                return .center
            case .top:
                return .top
            case .bottom:
                return .bottom
            case ._left:
                return .left
            case ._right:
                return .right
            }
    }
    
    func videoContentMode() -> AVLayerVideoGravity? {
            switch self {
            case .scaletofill:
                return .resize
            case .scaleaspectfit:
                return .resizeAspect
            case .scaleaspectfill:
                return .resizeAspectFill
            default:
                return .resizeAspectFill
            }
    }
}

extension BaseText {
    
    func textByLocale() -> String {
        let valueByLocale = LocaleHelper.valueByLocaleFor(dict: l10n, defaultLanguage: OnboardingService.shared.screenGraph?.defaultLanguage.rawValue)
        
        return valueByLocale
    }
    
    func textColor() -> UIColor {
        return (self.styles.color ?? "#FFFFFF").hexStringToColor
    }
    
}

extension Badge {
    
    func textByLocale() -> String {
        let valueByLocale = LocaleHelper.valueByLocaleFor(dict: l10n, defaultLanguage: OnboardingService.shared.screenGraph?.defaultLanguage.rawValue)
        
        return valueByLocale
    }
    
    func textColor() -> UIColor {
        return (self.styles.color ?? "#FFFFFF").hexStringToColor
    }
    
}

extension String {
    
    func applyWith(product: StoreKitProduct, currencyFormat: CurrencyFormatKind?) -> String {
        var text = self
        let currencyFormateForPrice = currencyFormat?.formatStyle() ?? .currency
        
        let price =  product.skProduct.localizedPriceFor(currencyFormat: currencyFormateForPrice) ?? ""
        let duration = product.subscriptionDescription?.periodUnitCountLocalizedUnitName ?? ""
        let pricePerDuration = "\(price)/\(duration)"

        let pricePerWeek = product.localizedPricePerWeek(currencyFormat: currencyFormateForPrice) ?? ""
        let pricePerMonth = product.localizedPricePerMonth(currencyFormat: currencyFormateForPrice) ?? ""
        
        let introOfferDuration = product.discounts.first?.period.periodUnitCountLocalizedUnitName ?? ""
//        let introOfferPrice = product.discounts.first?.localizedPrice ?? ""
        var introOfferPrice = product.discounts.first?.localizedPrice ?? ""

        if let intro = product.discounts.first {
            introOfferPrice =  product.skProduct.localizedPriceFor(intro.price, currencyFormat: currencyFormateForPrice) ?? introOfferPrice
        }
       
        let dict = ["@priceAndcurrency" : price,
                    "@duration" : duration,
                    "@price/duration" : pricePerDuration,
                    "@price/week" : pricePerWeek,
                    "@price/month" : pricePerMonth,

                    "@introPrice": introOfferPrice,
                    "@introDuration": introOfferDuration,
        ]
        
        for key in dict.keys {
            if let value = dict[key] {
                text =  text.replacingOccurrences(of: key, with: value)
            }
        }
        return text
    }
    
}

extension Text {
    
    func textByLocale() -> String {
        let valueByLocale = LocaleHelper.valueByLocaleFor(dict: l10n, defaultLanguage: OnboardingService.shared.screenGraph?.defaultLanguage.rawValue)
        
        return valueByLocale
    }
    
    
    
    func isAttributed() -> Bool {
        let labels = self.parameters.labels
        let links = self.parameters.links

//        if self.kind == ._default {
        if labels.isEmpty && links.isEmpty {

            return false
        } else {
            return true
        }
    }
    
    func textFor(product: StoreKitProduct, currencyFormat: CurrencyFormatKind?) -> String {
        let text = self.textByLocale().applyWith(product: product, currencyFormat: currencyFormat)
    
        return text
    }
    
    
    func textColor() -> UIColor {
        return (self.styles.color ?? "#FFFFFF").hexStringToColor
    }
    
    func textFont() -> UIFont {
        if let font =  self.styles.getFontSettings() {
            return font
        } else {
            var fontSize: CGFloat = 17.0
            if let size = self.styles.fontSize?.cgFloatValue {
                fontSize = size
            }
            return UIFont.systemFont(ofSize: fontSize, weight: .regular)
        }
    }
    
    func textParametersFrom(text: LabelBlock) -> [NSAttributedString.Key : Any] {
        
        var currentTagAttributes =  [NSAttributedString.Key : Any]()
      
        if let color = text.color?.hexStringToColor {
            currentTagAttributes[.foregroundColor] = color
        }
        
        if let color = text.backgroundColor?.hexStringToColor {
            currentTagAttributes[.backgroundColor] = color
        }
        
        if let font = text.getFontSettings() {
            currentTagAttributes[.font] = font
        }
        // Проверка и применение атрибутов параграфа
        let paragraphStyle = NSMutableParagraphStyle()
        
        // Проверка и установка выравнивания текста
        if let textAlign = text.textAlign {
            paragraphStyle.alignment = textAlign.alignment()
        } else {
            paragraphStyle.alignment = .left
        }
        
        paragraphStyle.lineBreakMode = .byWordWrapping

        // Проверка и установка высоты строки
        if let lineHeight = text.lineHeight {
            paragraphStyle.minimumLineHeight = CGFloat(lineHeight)
            paragraphStyle.maximumLineHeight = CGFloat(lineHeight)
        }
        
        currentTagAttributes[.paragraphStyle] = paragraphStyle
        
        return currentTagAttributes
    }
    
    func textParametersFrom(text: LabelBlock, defaultParameters: [NSAttributedString.Key : Any]) -> [NSAttributedString.Key : Any] {
        
        var currentTagAttributes =  defaultParameters
      
        if let color = text.color?.hexStringToColor {
            currentTagAttributes[.foregroundColor] = color
        }
        
        if let color = text.backgroundColor?.hexStringToColor {
            currentTagAttributes[.backgroundColor] = color
        }
        
        if let font = text.getFontSettings() {
            currentTagAttributes[.font] = font
        }
        // Проверка и применение атрибутов параграфа
        var paragraphStyle: NSMutableParagraphStyle
        if let paragraph = defaultParameters[.paragraphStyle] as? NSMutableParagraphStyle {
            paragraphStyle = paragraph
        } else {
            paragraphStyle = NSMutableParagraphStyle.init()
        }
        
        paragraphStyle.lineBreakMode = .byWordWrapping

        // Проверка и установка высоты строки
        if let lineHeight = text.lineHeight {
//            paragraphStyle.minimumLineHeight = CGFloat(lineHeight)
//            paragraphStyle.maximumLineHeight = CGFloat(lineHeight)
        }
        
        currentTagAttributes[.paragraphStyle] = paragraphStyle
        
        return currentTagAttributes
    }
    
    
    func textHeightBy(textWidth: CGFloat) -> CGFloat {
        let labelKey = self.textByLocale()
        if self.isAttributed() {
            let height = self.heightForAttributedString(width: textWidth)
            return height
        } else {
            let font: UIFont = self.textFont()
            
            let constraintRect = CGSize(width: textWidth, height: .greatestFiniteMagnitude)
            let boundingBox = labelKey.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
            
            return ceil(boundingBox.height)
        }
        
    }
    
    func textHeightBy(textWidth: CGFloat, product: StoreKitProduct?,  currencyFormat: CurrencyFormatKind?) -> CGFloat {
        guard let product = product else {
            if self.textByLocale().isEmpty {
                return 0.0
            } else {
                return textHeightBy(textWidth: textWidth)
            }
        }
        
        let labelKey = self.textByLocale().applyWith(product: product, currencyFormat: currencyFormat)
        if labelKey.isEmpty {
            return 0.0
        } else {
            let font: UIFont = self.textFont()
            
            let constraintRect = CGSize(width: textWidth, height: .greatestFiniteMagnitude)
            let boundingBox = labelKey.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
            
            return ceil(boundingBox.height)
        }
    }
    
}

extension Date {
    
    var timestampString: String {
        Date.timestampFormatter.string(from: self)
    }
    
    static private var timestampFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        return dateFormatter
    }
}


protocol Title {
    var title: Text {get set}
}

protocol Subtitle {
    var subtitle: Text {get set}
}

protocol NextButton {
    var next: Button? {get set}
}

extension LabelBlock {
    
    func fontWeight(weight: Double) -> UIFont.Weight {
        switch weight {
        case 0...100.0:
            return .ultraLight
        case 100...200.0:
            return .thin
        case 200...300.0:
            return .light
        case 300...400.0:
            return .regular
        case 400...500.0:
            return .medium
        case 500...600.0:
            return .semibold
        case 600...700.0:
            return .bold
        case 700...800.0:
            return .heavy
        case 800...900.0:
            return .black
            
        default:
            return .regular
        }
    }
    
    func getFontSettings1() -> UIFont? {
        let text = self
        
        if let fontSize = text.fontSize?.cgFloatValue {
            var labelFont: UIFont

            if let fontWeightRaw = text.fontWeight {
                let fontWeight = self.fontWeight(weight: fontWeightRaw)
                labelFont = UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
            } else {
                labelFont = UIFont.systemFont(ofSize: fontSize, weight: .regular)
            }
            
            if let fontFamile = text.fontFamily {
                switch fontFamile {
                case .sfPro:
                    break
                case .sfProrounded:
                    labelFont = labelFont.rounded()
                case .sfMono:
                    labelFont = labelFont.monospaced()
                case .newYork:
                    labelFont = labelFont.newYorked()
                }
            }
            return labelFont
        }
        
        return nil
    }
    
    func getFontSettings() -> UIFont? {
        
        let text = self
        
        if let fontSize = text.fontSize?.cgFloatValue {
            var labelFont: UIFont

            if let fontWeightRaw = text.fontWeight {
                let fontWeght =  self.fontWeight(weight: fontWeightRaw)
                labelFont = UIFont.systemFont(ofSize: fontSize, weight: fontWeght)
            } else {
                labelFont = UIFont.systemFont(ofSize: fontSize, weight: .regular)
            }
            
            if let customFont = OnboardingService.shared.customFontNames, let fontFamily = text.fontFamily, let fontName = customFont[fontFamily]  {
                if let customFont = UIFont(name: fontName, size: fontSize) {
                    labelFont = customFont
                } else {
                    labelFont = UIFont.systemFont(ofSize: fontSize, weight: .regular)
                }
            }
           
            if let fontFamily = text.fontFamily {
                switch fontFamily {
                case .sfPro:
                    break
                case .sfProrounded:
                    labelFont = labelFont.rounded()
                case .sfMono:
                    labelFont = labelFont.monospaced()
                case .newYork:
                    labelFont = labelFont.newYorked()
                }
            }
            return  labelFont
        }
        
        return nil
    }
}


extension BadgeBlock {
    
    func fontWeight(weight: Double) -> UIFont.Weight {
        switch weight {
        case 0...100.0:
            return .ultraLight
        case 100...200.0:
            return .thin
        case 200...300.0:
            return .light
        case 300...400.0:
            return .regular
        case 400...500.0:
            return .medium
        case 500...600.0:
            return .semibold
        case 600...700.0:
            return .bold
        case 700...800.0:
            return .heavy
        case 800...900.0:
            return .black
            
        default:
            return .regular
        }
    }
    
    func getFontSettings() -> UIFont? {
        
        let text = self
        
        if let fontSize = text.fontSize?.cgFloatValue {
            var labelFont: UIFont

            if let fontWeightRaw = text.fontWeight {
                let fontWeght =  self.fontWeight(weight: fontWeightRaw)
                labelFont = UIFont.systemFont(ofSize: fontSize, weight: fontWeght)
            } else {
                labelFont = UIFont.systemFont(ofSize: fontSize, weight: .regular)
            }
            
            if let fontFamile = text.fontFamily {
                switch fontFamile {
                case .sfPro:
                    break
                case .sfProrounded:
                    labelFont = labelFont.rounded()
                case .sfMono:
                    labelFont = labelFont.monospaced()
                case .newYork:
                    labelFont = labelFont.newYorked()
                }
            }
            return  labelFont
        }
        
        return nil
    }
}

extension LabelPosition {

    func alignment() -> NSTextAlignment {
        switch self {
        case ._right:
            return NSTextAlignment.right
        case ._left:
            return NSTextAlignment.left
        case .center:
            return NSTextAlignment.center
        }
    }
    
    func paragraphAlignment() -> NSTextAlignment {
        switch self {
        case ._right:
            return NSTextAlignment.right
        case ._left:
            return NSTextAlignment.left
        case .center:
            return NSTextAlignment.center
        }
    }
    
}

extension UIImageView  {
    
    func applyStaticCheckbox(isSelected: Bool) {
        let imageName = isSelected ? "Circle_on" : "Circle_off"
        
        if let image = UIImage.init(named: "\(imageName).png", in: .module, with: nil) {
            self.image = image.withRenderingMode(.alwaysTemplate)
        }
    }
    
    func apply(checkbox: CheckBox?, isSelected: Bool) {
        guard let checkbox else { return }
        
        var imageName = ""

        switch checkbox.kind {
        case .circle:
            if isSelected {
                imageName = (checkbox.styles.isBackgroundFilled ?? false) ? "Circle_on_dark" : "Circle_on"
            } else {
                imageName = "Circle_off"
            }
        case .square:
            if isSelected {
                imageName = (checkbox.styles.isBackgroundFilled ?? false) ? "rounded_on_dark" : "Square_Rounded_on"
            } else {
                imageName = "Square_Rounded_off"
            }
        }
    
        
        if let image = UIImage.init(named: "\(imageName).png", in: .module, with: nil) {
            self.image = image.withRenderingMode(.alwaysTemplate)
            let tintColor = isSelected ? checkbox.selectedBlock.styles.color : checkbox.styles.color
            
            self.tintColor = tintColor?.hexStringToColor ?? .clear
        }
        
        
        if !isSelected {
            if  let unselectedImage = OnboardingService.shared.unselectedCheckBoxImage  {
                self.image = unselectedImage.withRenderingMode(.alwaysTemplate)
                let tintColor = checkbox.styles.color
                
                self.tintColor = tintColor?.hexStringToColor ?? .clear
            }
        } else {
            if  let selectedImage = OnboardingService.shared.selectedCheckBoxImage {
                self.image = selectedImage.withRenderingMode(.alwaysTemplate)
                let tintColor =  checkbox.selectedBlock.styles.color
                
                self.tintColor = tintColor?.hexStringToColor ?? .clear
            }
        }

    }
    
    func apply(checkbox: BaseCheckBox?, isSelected: Bool) {
        guard let checkbox else { return }
        
        var imageName = ""
        switch checkbox.kind {
        case .circle:
            imageName = isSelected ? "Circle_on" : "Circle_off"
        case .square:
            imageName = isSelected ? "Square_Rounded_on" : "Square_Rounded_off"
        }
        
        if let image = UIImage.init(named: "\(imageName).png", in: .module, with: nil) {
            self.image = image.withRenderingMode(.alwaysTemplate)
            let tintColor = isSelected ? checkbox.selectedBlock.styles.color : checkbox.styles.color
            
            self.tintColor = tintColor?.hexStringToColor
        }
        
        if !isSelected {
            if  let unselectedImage = OnboardingService.shared.unselectedCheckBoxImage  {
                self.image = unselectedImage.withRenderingMode(.alwaysTemplate)
                let tintColor = checkbox.styles.color
                
                self.tintColor = tintColor?.hexStringToColor ?? .clear
            }
        } else {
            if  let selectedImage = OnboardingService.shared.selectedCheckBoxImage {
                self.image = selectedImage.withRenderingMode(.alwaysTemplate)
                let tintColor =  checkbox.selectedBlock.styles.color
                
                self.tintColor = tintColor?.hexStringToColor ?? .clear
            }
        }
    }
    
}

extension UIPickerView {
    
    func apply(picker: Picker?) {
        guard let picker = picker else { return }
        
        for (n, _) in picker.wheels.enumerated() {
            let itemIndex = Int(n)
            if  let item  = picker.defaultValuesFor(wheelIndex: itemIndex) {
                let wheelItems = picker.pickerValuesFor(wheelIndex: itemIndex)
                if let indexPosition = wheelItems.firstIndex(of: item){
                    self.selectRow(indexPosition, inComponent: itemIndex, animated: true)
                }
            }
        }
    }

}


extension String {
    
    func attributedStringFromTags(defaultAttributes: [NSAttributedString.Key: Any],
                                   tagAttributes: [String: [NSAttributedString.Key: Any]]) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self, attributes: defaultAttributes)
        
        // Regular expression to match tags
        let regex = try! NSRegularExpression(pattern: "<(\\w+)>(.*?)</\\1>", options: [])
        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
        
        // Iterate through matches in reverse order to avoid range issues
        for match in matches.reversed() {
            if let tagRange = Range(match.range(at: 1), in: self),
               let contentRange = Range(match.range(at: 2), in: self) {
                let tag = String(self[tagRange])
                let content = String(self[contentRange])
                
                // Define the range for the content
                let nsRange = NSRange(contentRange, in: self)
                
                // Apply attributes
                attributedString.addAttributes(tagAttributes[tag] ?? [:], range: nsRange)
                
                // Remove the tags from the string
                attributedString.replaceCharacters(in: match.range, with: content)
            }
        }
        
        return attributedString
    }
}

extension Text {
    
    func heightForAttributedString(width: CGFloat) -> CGFloat {
        let height = self.heightForAttributedString(self.attributedText(), width: width)
        return height
    }
    
    func heightForAttributedString(_ attributedString: NSAttributedString, width: CGFloat) -> CGFloat {
        // Создаем контейнер для текста с указанной шириной и практически неограниченной высотой
        let textContainer = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = 0  // Убираем внутренние отступы контейнера

        // Инициализируем хранилище текста с атрибутированной строкой
        let textStorage = NSTextStorage(attributedString: attributedString)

        // Создаем менеджер макета и связываем его с хранилищем текста и контейнером
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Принудительно размещаем глифы в контейнере, чтобы определить фактическое использованное пространство
        layoutManager.ensureLayout(for: textContainer)

        // Получаем ректангл, описывающий область, занимаемую текстом
        let rect = layoutManager.usedRect(for: textContainer)

        // Возвращаем округленное вверх значение высоты ректангла
        return ceil(rect.height)
    }

    
    func attributedText() -> NSAttributedString {
        
        let titleLabelKey = self.textByLocale()

        let labels = self.parameters.labels
        let links = self.parameters.links
        
        var tagAttributes = [String: [NSAttributedString.Key: Any]]()
        var linksValue = [String: String]()

        let defaultAttributes = self.textParametersFrom(text: self.styles)

        for key in labels.keys {
            if let array = labels[key] {
                let attributes = textParametersFrom(text: array, defaultParameters: defaultAttributes)
                tagAttributes[key] = attributes
            }
        }
        for key in links.keys {
            let screenId = substringBeforeDot(in: links[key])
            if  !screenId.isEmpty {
                if let screen = OnboardingService.shared.screenGraph?.screens[screenId] {
                    if let indexes  = OnboardingService.shared.onboardingUserData[screenId] as? [Int] {
                        let value = screen.listValuesFor(indexes: indexes)
                        linksValue["\(key)"] = value
                    } else if let indexes  = OnboardingService.shared.onboardingUserData[screenId] as? Int {
                        let value = screen.listValuesFor(indexes: [indexes])
                        linksValue["\(key)"] = value
                    } else if let value  = OnboardingService.shared.onboardingUserData[screenId] as? String {
                        linksValue["\(key)"] = value
                    }
                }
                if let value  = OnboardingService.shared.onboardingUserData[screenId] as? String {
                    linksValue["\(key)"] = value
                }
            }
        }
        
        
        let attributesText = attributedString(from: titleLabelKey, replacingConstantsWith: linksValue, tagAttributes: tagAttributes, defaultAttributes: defaultAttributes)
        
        return attributesText
    }
    
    
    func substringBeforeDot(in string: String?) -> String {
        // Проверяем, что строка не nil
        guard let string = string else {
            // Если строка nil, возвращаем пустую строку
            return ""
        }

        // Поиск индекса первой точки в строке
        if let dotIndex = string.firstIndex(of: ".") {
            // Возвращаем подстроку от начала строки до найденной точки
            return String(string[..<dotIndex])
        }
        
        // Если точка не найдена, возвращаем исходную строку целиком
        return string
    }
    
    func attributedString(from string: String,
                          replacingConstantsWith replacements: [String: String]? = nil,
                          tagAttributes: [String: [NSAttributedString.Key: Any]]? = nil,
                          defaultAttributes: [NSAttributedString.Key: Any]? = nil) -> NSAttributedString {
        
        var resultString = string
        let constantPattern = "@([A-Za-z0-9_]+)"
        let tagPattern = "<(.+?)>([\\s\\S]+?)</\\1>"

        // Замена констант
        if let replacements = replacements {
            let regex = try! NSRegularExpression(pattern: constantPattern, options: [])
            
            // Используем NSMutableAttributedString для последовательной замены
            let mutableAttributedString = NSMutableAttributedString(string: resultString)
            let matches = regex.matches(in: resultString, options: [], range: NSRange(location: 0, length: resultString.utf16.count))

            // Проходим по матчам в обратном порядке, чтобы избежать проблем с индексацией
            for match in matches.reversed() {
                if let range = Range(match.range(at: 1), in: resultString) {
                    let constantKey = String(resultString[range])
                    
                    if let replacementText = replacements[constantKey] {
                        let fullRange = Range(match.range, in: resultString)!
                        mutableAttributedString.replaceCharacters(in: NSRange(fullRange, in: resultString), with: replacementText)
                        resultString.replaceSubrange(fullRange, with: replacementText)
                    }
                }
            }
            
            resultString = mutableAttributedString.string
        }

        let attributedString = NSMutableAttributedString(string: resultString, attributes: defaultAttributes)

        // Обработка тегов
        if let tagAttributes = tagAttributes {
            let tagRegex = try! NSRegularExpression(pattern: tagPattern, options: [])
            let tagMatches = tagRegex.matches(in: attributedString.string, options: [], range: NSRange(location: 0, length: attributedString.length))

            // Проходим по матчам в обратном порядке, чтобы избежать проблем с индексацией
            for match in tagMatches.reversed() {
                let tagNameRange = match.range(at: 1)
                let textRange = match.range(at: 2)
                
                if let tagName = Range(tagNameRange, in: attributedString.string),
                   let currentTagAttributes = tagAttributes[String(attributedString.string[tagName])] {
                    
                    let nsTextRange = textRange
                    let textInRange = attributedString.attributedSubstring(from: nsTextRange).string
                    
                    attributedString.replaceCharacters(in: nsTextRange, with: NSAttributedString(string: textInRange, attributes: currentTagAttributes))
                    
                    // Удаление тегов
                    let closingTagRange = NSRange(location: match.range.upperBound - ("</\(String(attributedString.string[tagName]))>").count, length: ("</\(String(attributedString.string[tagName]))>").count)
                    let openingTagRange = NSRange(location: match.range.location, length: ("<\(String(attributedString.string[tagName]))>").count)
                    attributedString.deleteCharacters(in: closingTagRange)
                    attributedString.deleteCharacters(in: openingTagRange)
                }
            }
        }

        return attributedString
    }



}

extension UILabel  {

    func apply(text: Text?) {
        guard let text = text else {
            self.isHidden = true
            return
        }
        
        let titleLabelKey = text.textByLocale()
        
        self.text = titleLabelKey
        
        if titleLabelKey.isEmpty {
            self.isHidden = true
        }

        if !text.isAttributed() {
            self.apply(text: text.styles)
        } else {
            self.attributedText = text.attributedText()
        }
    }
    
   

    private func removeRemainingTags(from attributedString: NSMutableAttributedString) -> NSAttributedString {
        let pattern = "<[^>]+>"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let nsString = attributedString.string as NSString
        let matches = regex.matches(in: nsString as String, options: [], range: NSRange(location: 0, length: nsString.length))

        // Удаление совпадений в обратном порядке, чтобы не нарушить диапазоны
        for match in matches.reversed() {
            attributedString.deleteCharacters(in: match.range)
        }

        return attributedString
    }
    
    
    func apply(badge: Badge?) {
        guard let badge = badge else {
            self.isHidden = true
            return
        }
        
        let titleLabelKey = badge.textByLocale()
        
        self.text = titleLabelKey
        
        if titleLabelKey.isEmpty {
            self.isHidden = true
        }
        
        self.apply(text: badge.styles)
    }
    
    func apply(text: BadgeBlock?) {
        guard let text = text else {
            self.isHidden = true
            return
        }
        
        if let alignment = text.textAlign {
            self.textAlignment = alignment.alignment()
        }
        
        self.font = text.getFontSettings()
        self.textColor = text.color?.hexStringToColor
    }
    
     public func apply(text: BaseText?) {
        guard let text = text else {
            self.isHidden = true
            return
        }
        
        let titleLabelKey = text.textByLocale()
        self.text = titleLabelKey
        
        if titleLabelKey.isEmpty {
            self.isHidden = true
        }
        
        self.apply(text: text.styles)
    }
    
    func apply(text: LabelBlock?) {
        guard let text = text else {
            self.isHidden = true
            return
        }
        
        if let alignment = text.textAlign {
            self.textAlignment = alignment.alignment()
        }
        
        self.font = text.getFontSettings()
        self.textColor = text.color?.hexStringToColor
    }
    
    func textParametersFrom1(text: LabelBlock) -> [NSAttributedString.Key: Any] {
        var currentTagAttributes = [NSAttributedString.Key: Any]()

        // Проверка и применение цвета текста
        if let colorString = text.color {
            currentTagAttributes[.foregroundColor] = colorString.hexStringToColor
        }

        // Проверка и применение шрифта
        if let font = text.getFontSettings() {
            currentTagAttributes[.font] = font
        }

        // Проверка и применение атрибутов параграфа
        let paragraphStyle = NSMutableParagraphStyle()
        var paragraphStyleIsSet = false

        // Проверка и установка выравнивания текста
        if let textAlign = text.textAlign {
            paragraphStyle.alignment = textAlign.alignment()
            paragraphStyleIsSet = true
        }

        // Проверка и установка высоты строки
        if let lineHeight = text.lineHeight, let font = currentTagAttributes[.font] as? UIFont {
//            paragraphStyle.minimumLineHeight = CGFloat(lineHeight)
//            paragraphStyle.maximumLineHeight = CGFloat(lineHeight)
//            paragraphStyle.lineSpacing = CGFloat(lineHeight) - font.lineHeight
//            paragraphStyleIsSet = true
        }

        // Применение стиля параграфа, если были установлены какие-либо свойства
        if paragraphStyleIsSet {
            currentTagAttributes[.paragraphStyle] = paragraphStyle
        }

        return currentTagAttributes
    }


    
    func textParametersFrom(text: LabelBlock) -> [NSAttributedString.Key : Any] {
        
        var currentTagAttributes =  [NSAttributedString.Key : Any]()
      
        if let color = text.color?.hexStringToColor {
            currentTagAttributes[.foregroundColor] = color
        }
        
        if let color = text.backgroundColor?.hexStringToColor {
            currentTagAttributes[.backgroundColor] = color
        }
        
        if let font = text.getFontSettings() {
            currentTagAttributes[.font] = font
        }
        // Проверка и применение атрибутов параграфа
        let paragraphStyle = NSMutableParagraphStyle()
        var paragraphStyleIsSet = false
        
        // Проверка и установка выравнивания текста
        if let textAlign = text.textAlign {
            paragraphStyle.alignment = textAlign.alignment()
            paragraphStyleIsSet = true
        }
        
        // Проверка и установка высоты строки
        if let lineHeight = text.lineHeight, let font = currentTagAttributes[.font] as? UIFont {
//            paragraphStyle.minimumLineHeight = CGFloat(lineHeight)
//            paragraphStyle.maximumLineHeight = CGFloat(lineHeight)
//            paragraphStyle.lineSpacing = CGFloat(lineHeight) - font.lineHeight
//            paragraphStyleIsSet = true
        }
        
        // Применение стиля параграфа, если были установлены какие-либо свойства
        if paragraphStyleIsSet {
            currentTagAttributes[.paragraphStyle] = paragraphStyle
        }
//        if let alignment = text.textAlign  {
//            let paragraphStyle = NSMutableParagraphStyle()
//            paragraphStyle.alignment = alignment.alignment()
//            
//            currentTagAttributes[.paragraphStyle] = paragraphStyle
//        }
        
        return currentTagAttributes
    }
    
    func setLineSpacing(lineSpacing: CGFloat = 0.0, lineHeightMultiple: CGFloat = 0.0) {
        guard let labelText = self.text else { return }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineHeightMultiple = lineHeightMultiple
        
        let attributedString:NSMutableAttributedString
        
        if let labelAttributedText = self.attributedText {
            attributedString = NSMutableAttributedString(attributedString: labelAttributedText)
        } else {
            attributedString = NSMutableAttributedString(string: labelText)
        }
        // (Swift 4.2 and above) Line spacing attribute
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
        // (Swift 4.1 and 4.0) Line spacing attribute
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
        
        self.attributedText = attributedString
    }
    
    
    func wrapLabelInUIView(padding: BoxBlock? = nil) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        containerView.addSubview(self)
        
        if let padding = padding {
            let bottom = -1 * (padding.paddingBottom ?? 0)
            let trailing = -1 * (padding.paddingRight ?? 0)

            NSLayoutConstraint.activate([
                self.topAnchor.constraint(equalTo: containerView.topAnchor, constant: padding.paddingTop ?? 0),
                self.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: bottom),
                self.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding.paddingLeft ?? 0),
                self.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: trailing)
            ])
        } else {
            NSLayoutConstraint.activate([
                self.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
                self.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0),
                self.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
                self.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0)
            ])
        }
        
        return containerView
    }
    
}

extension UIFont {
    
    func rounded() -> UIFont {
        guard let descriptor = fontDescriptor.withDesign(.rounded) else {
            return self
        }

        return UIFont(descriptor: descriptor, size: pointSize)
    }
    
    func monospaced() -> UIFont {
        guard let descriptor = fontDescriptor.withDesign(.monospaced) else {
            return self
        }

        return UIFont(descriptor: descriptor, size: pointSize)
        
    }
    
    func newYorked() -> UIFont {
        guard let descriptor = fontDescriptor.withDesign(.serif) else {
            return self
        }

        return UIFont(descriptor: descriptor, size: pointSize)
    }
}

extension VerticalAlignment {
    
    func verticalAlignment() -> CollectionContentVerticalAlignment {
        switch self {
        case .top:
            return CollectionContentVerticalAlignment.top
        case .bottom:
            return CollectionContentVerticalAlignment.bottom
        case .center:
            return CollectionContentVerticalAlignment.center
        }
    }
    
}


extension Button {
    
    func textColor() -> UIColor {
        switch self.content {
        case .typeBaseImage(_):
            return .black
        case .typeBaseText(let value):
            return value.textColor()            
        }
    }
    
}

extension UIButton: UIImageLoader {
   
    func apply(button: Button?, isBackButton: Bool = false) {
        guard let button = button else {
            self.isHidden = true
            return
        }
        var text = ""
        
        switch button.content {
        case .typeBaseImage(_):
            let image = UIImage(named: "Circle_on")
            self.setBackgroundImage(image, for: .normal)
        case .typeBaseText(let value):
            text = value.textByLocale()
            
            if text.isEmpty, var emptyTextImage = UIImage(systemName: "chevron.left"), isBackButton {
               
                emptyTextImage = emptyTextImage.withRenderingMode(.alwaysTemplate)
                self.tintColor = value.styles.color?.hexStringToColor
                imageView?.contentMode = .scaleAspectFit
                self.setBackgroundImage(emptyTextImage, for: .normal)
            } else {
                if !(button.styles.fullWidth ?? true) {
                    text = "        \(text)        "
                }
                
                self.titleLabel?.font = value.styles.getFontSettings()
                self.setTitle(text, for: .normal)
                
                if let color = value.styles.color?.hexStringToColor {
                    self.setTitleColor(color, for: .normal)
                }
            }

            
            self.backgroundColor = button.styles.backgroundColor?.hexStringToColor
        }
    
        self.layer.cornerRadius = button.styles.borderRadiusFloat()
        self.layer.borderWidth = button.styles.borderWidthFloat()
        self.layer.borderColor = (button.styles.borderColor?.hexStringToColor ?? .clear).cgColor
    }
    
    func apply(textLabel: Text?) {
        guard let textLabel = textLabel else {
            self.isHidden = true
            return
        }
        
        let text = textLabel.textByLocale()
        
        self.titleLabel?.font = textLabel.styles.getFontSettings()
        self.setTitle(text, for: .normal)
        
        if let color = textLabel.styles.color?.hexStringToColor {
            self.setTitleColor(color, for: .normal)
        }
    }
    
    func apply(button: Button?, product: StoreKitProduct, currencyFormat: CurrencyFormatKind?) {
        guard let button = button else {
            self.isHidden = true
            return
        }
        var text = ""
        
        switch button.content {
        case .typeBaseImage(_):
            break
        case .typeBaseText(let value):
            text = value.textByLocale().applyWith(product: product, currencyFormat: currencyFormat)
            
            self.setTitle(text, for: .normal)
        }
    }
    
    func apply(navLink: NavLink?, isBackButton: Bool = false) {
        guard let button = navLink else {
            self.isHidden = true
            return
        }
        
        switch button.content {
        case .typeBaseImage(_): break

        case .typeBaseText(let value):
            let text = value.textByLocale()
            
            self.titleLabel?.font = value.styles.getFontSettings()
            self.setTitle(text, for: .normal)
            
            if let color = value.styles.color?.hexStringToColor {
                self.setTitleColor(color, for: .normal)
            }
        }
    }
    
}

extension Button {
    
    func isDefaultBackIcon() -> Bool {
        switch self.content {
        case .typeBaseImage(_):
            return true
        case .typeBaseText(let value):
            let text = value.textByLocale()
            
            if text.isEmpty {
                return true
            }
        }
        return false
    }
}



extension ButtonBlock {
    
    func borderRadiusFloat() -> CGFloat {
        return CGFloat((self.borderRadius ?? 0).floatValue)
    }
    
    func borderWidthFloat() -> CGFloat {
        return CGFloat((self.borderWidth ?? 0).floatValue)
    }
    
}

extension UITextField {
    
    func apply(field: Field?) {
        guard let field = field else { return }

        self.backgroundColor = field.styles.backgroundColor?.hexStringToColor
                
        switch field.type {
        case .string:
            self.keyboardType = .default
        case .int:
            self.keyboardType = .numberPad
        case .double:
            self.keyboardType = .decimalPad
        case .date:
            if #available(iOS 15.0, *) {
                self.textContentType = .dateTime
            } else {
                self.keyboardType = .decimalPad
            }
        }
        apply(text: field.placeholder)
    }
    
    func apply(text: BaseText?) {
        guard let text = text else {
            self.isHidden = true
            return
        }
        
        let placeholderText = text.textByLocale()
        let placeholderColor = text.styles.color?.hexStringToColor ?? OnboardingService.shared.placeHolderColor

        self.attributedPlaceholder = NSAttributedString(
            string: placeholderText,
            attributes: [NSAttributedString.Key.foregroundColor: placeholderColor]
        )
        
        self.apply(text: text.styles)
    }
    
    func apply(text: LabelBlock?) {
        guard let text = text else {
            self.isHidden = true
            return
        }
        
        if let alignment = text.textAlign {
            self.textAlignment = alignment.alignment()
        }
        
        self.font = text.getFontSettings()
        self.textColor = text.color?.hexStringToColor
    }
    
}

extension UIView {
    
    func apply(listStyle: ListBlock?) {
        guard let style = listStyle else { return }
        
        if let color  = style.backgroundColor {
            self.backgroundColor = color.hexStringToColor
        } else {
            self.backgroundColor = .clear
        }

        if let color  = style.borderColor {
            self.layer.borderColor = color.hexStringToColor.cgColor
        } else {
            self.layer.borderColor  = UIColor.clear.cgColor
        }
        
        self.layer.cornerRadius = CGFloat((style.borderRadius ?? 0).floatValue)
        self.layer.borderWidth = CGFloat((style.borderWidth ?? 0).floatValue)
    }
    
}


extension NavigationBar {
    
    func isNavigationBarAvailable() -> Bool {
        if skip != nil || back != nil || pageIndicator != nil {
            return true
        } else {
            return false
        }
    }
    
}


extension Footer {
    
    func isFooterAvailable() -> Bool {
        if button1 == nil && button2 == nil {
            return false
        } else {
            return true
        }
    }
    
}

extension ConditionedAction {
    
    func checkRuleFor(screenGraph: ScreensGraph, screenValues:[String: Any]) -> Bool {
        for condition in rule {
            if let key = condition.key.components(separatedBy: ".").first, let screen = screenGraph.screens[key] {
                let screenValueType = screen.screenValueType()

                if let screenValue = screenValues[key] {
                    if screenValueType == ValueTypes.anyDict {
                       let customScreenValue = valueFor(value: screenValue, condition: condition)
                        if !condition.compare(arg1: customScreenValue.0, arg2: condition.value, valueType: customScreenValue.1) {
                            return false
                        }
                    } else {
                        if !condition.compare(arg1: screenValue, arg2: condition.value, valueType: screenValueType) {
                            return false
                        }
                    }
                } else {
//                    if screen value is empty we could not compare it with condition
                    return false
                }
            }
        }
        
        return true
    }
    
    func valueFor(value:  Any, condition: Condition) -> (String, ValueTypes) {
        guard let customScreenValues = value as? [String : CustomScreenInputValue] else { return ("", ValueTypes.none) }

        let array = condition.key.components(separatedBy: ".")
        if array.count >= 2 {
            var key = array[1]
            key = key.replacingOccurrences(of: "input[\'", with: "").replacingOccurrences(of: "\']", with: "")
            
            guard let customScreenInout = customScreenValues[key] else { return ("", ValueTypes.none) }

            switch customScreenInout.type {
            case .int:
                return (customScreenInout.value, .int)
            case .double:
                return (customScreenInout.value, .double)
            case .string:
                return (customScreenInout.value, .string)
            default:
                return (customScreenInout.value, .none)
            }
           
        }
        
        return ("", ValueTypes.none)
    }
    
}


extension Picker {
    
    func pickerValuesFor(wheelIndex: Int) -> [String] {
        
        if let listOptions = pickerWillListOption(itemIndex: wheelIndex) {
            if let valueByLocale = LocaleHelper.valueByLocaleFor(anyDict: listOptions.localizedOptions) as? [String]{
                return valueByLocale
            }
            
            return listOptions.localizedOptions.first?.value ?? ["1"]
        } else if let rangeOptions = pickerWillRangeOption(itemIndex: wheelIndex) {
            let from = rangeOptions.from.intValue
            let to = rangeOptions.to.intValue

            if from > to {
                return [" "]
            }
            
            var rangeStringValues = [String]()
            for n in from ... to {
                rangeStringValues.append("\(n)")
            }

            return rangeStringValues
        }
        
        return ["1"]
    }
    
    func defaultValuesFor(wheelIndex: Int) -> String? {
        let wheel = self.wheels [wheelIndex]
        let valueByLocale = LocaleHelper.valueByLocaleFor(dict: wheel.defaultValue, defaultLanguage: OnboardingService.shared.screenGraph?.defaultLanguage.rawValue)
        
        return valueByLocale
    }
    
    func pickerWillListOption(itemIndex: Int) -> PickerListOptions? {
        let options = self.wheels[itemIndex].options
        
        switch options {
        case .typePickerListOptions(let value):
            return value
            
        case .typePickerRangeOptions(_):
            return nil
        }
    }
    
    func pickerWillRangeOption(itemIndex: Int) -> PickerRangeOptions? {
        let options = self.wheels[itemIndex].options

        switch options {
        case .typePickerListOptions(_):
            return nil
            
        case .typePickerRangeOptions(let value):
            return value
        }
    }
    
}



extension Condition {
    
    func compare(arg1: Any, arg2: String, valueType: ValueTypes ) -> Bool {
        switch valueType{
        case .string:
            guard let value = arg1 as? String else { return false }
            switch self._operator {
            case .eq:
                return value == arg2
            case .neq:
                return value != arg2
            case ._in:
                return arg2.contains(value)
            case .notin:
                return !arg2.contains(value)
            default:
                return false
            }
        case .int:
            if let value = (arg1 as? String), value == "", self._operator == .neq {
                return true
            }
            
            guard let value = (arg1 as? String)?.intValue, let value1 = arg2.intValue else { return false }
            
            switch self._operator {
            case .eq:
                return value == value1
            case .neq:
                return value != value1
            case .lt:
                return value < value1
            case .gt:
                return value > value1
            case .lte:
                return value <= value1
            case .gte:
                return value >= value1
                
            default:
                return false
            }
        case .double:
            if let value = (arg1 as? String), value == "", self._operator == .neq {
                return true
            }
            
            guard let value = (arg1 as? String)?.doubleValue, let value1 = arg2.doubleValue else { return false }
           
            switch self._operator {
            case .eq:
                return value == value1
            case .neq:
                return value != value1
            case .lt:
                return value < value1
            case .gt:
                return value > value1
            case .lte:
                return value <= value1
            case .gte:
                return value >= value1

            default:
                return false
            }
        case .date:
            guard let value = arg1 as? Date, let value1 = arg2.dateFromISO8601String else { return false }
           
            switch self._operator {
            case .eq:
                return value == value1
            case .neq:
                return value != value1
            case .lt:
                return value < value1
            case .gt:
                return value > value1
            case .lte:
                return value <= value1
            case .gte:
                return value >= value1

            default:
                return false
            }
        case .intArray:
            guard let value = arg1 as? [Int], let value1 = arg2.intArray else { return false }
           
            switch self._operator {
            case .eq:
                return value1.equalElementsWith(array: value)
            case .neq:
                return !value1.equalElementsWith(array: value)
            case ._in:
                if value.isEmpty {
                    return false
                }
                return value1.contains(value)
            case .notin:
                return !value1.contains(value)
            case .gte:
                if value.isEmpty {
                    return false
                }
                return value.contains(value1)
                
            default:
                return false
            }
        case .none:
            return true
        case .anyDict:
            guard let value = arg1 as? CustomScreenInputValue else { return false }

            switch value.type {
            case .int:
                return compare(arg1: value.value, arg2: arg2, valueType: .int)
            case .double:
                return compare(arg1: value.value, arg2: arg2, valueType: .double)
            case .string:
                return compare(arg1: value.value, arg2: arg2, valueType: .string)
            default:
                return true
            }
        case .dateArray:
            return true
        case .bool:
            guard let value = arg1 as? Bool else { return false }
            
            let value1 = arg2.boolValue
            
            switch self._operator {
            case .eq:
                return value == value1
            case .neq:
                return value != value1
            default:
                return false
            }

        case .intArrayFromInt:
            guard let value = (arg1 as? Int), let value1 = arg2.intArray else { return false }
           
            let valueAsArray = [value]
            switch self._operator {
            case .eq:
                return value1.equalElementsWith(array: valueAsArray)
            case .neq:
                return !value1.equalElementsWith(array: valueAsArray)
            case ._in:
                if valueAsArray.isEmpty {
                    return false
                }
                return value1.contains(valueAsArray)
            case .notin:
                return !value1.contains(valueAsArray)
                
            default:
                return false
            }
        }
    }
}

enum ValueTypes: String {
    case string = "string"
    case int = "int"
    case double = "double"
    case date = "date"
    case intArray = "intArray"
    case intArrayFromInt = "intArrayFromInt"
    case anyDict = "anyDict"
    case dateArray = "dateArray"
    case bool = "bool"
    case none = "none"
}

extension Screen {
    
    func screenValueType() -> ValueTypes  {
        switch self._struct {
        case .typeScreenBasicPaywall(_):
            return ValueTypes.string
        case .typeScreenImageTitleSubtitles(_):
            return ValueTypes.none
        case .typeScreenProgressBarTitle(_):
            return ValueTypes.none
        case .typeScreenTableMultipleSelection(_):
            return ValueTypes.intArray
        case .typeScreenTableSingleSelection(_):
            return ValueTypes.intArrayFromInt
        case .typeScreenTitleSubtitleField(let value):
            return ValueTypes.init(rawValue: value.field.type.rawValue) ?? ValueTypes.none
        case .typeScreenImageTitleSubtitleList(_):
            return ValueTypes.none
        case .typeScreenTwoColumnMultipleSelection(_):
            return ValueTypes.intArray
        case .typeScreenTwoColumnSingleSelection(_):
            return ValueTypes.intArrayFromInt
        case .typeCustomScreen(_):
            return ValueTypes.anyDict
        case .typeScreenTooltipPermissions(_):
            return ValueTypes.bool
        case .typeScreenImageTitleSubtitleMultipleSelectionList(_):
            return ValueTypes.intArray
        case .typeScreenImageTitleSubtitlePicker(let value):
            return ValueTypes.init(rawValue: value.picker.dataType.rawValue) ?? ValueTypes.none
        case .typeScreenTitleSubtitleCalendar(_):
            return ValueTypes.none
        case .typeScreenSlider(_):
            return ValueTypes.none
        case .typeScreenTitleSubtitlePicker(let value):
            return ValueTypes.init(rawValue: value.picker.dataType.rawValue) ?? ValueTypes.none
        }
    }
    
    func containerToTop() -> Bool  {
        switch self._struct {
        case .typeScreenImageTitleSubtitles(let value):
            return value.image.styles.imageKind == .imageKind2
        case .typeScreenTwoColumnMultipleSelection(let value):
            let isToTop = isContainerReadyToTopAlignmentWith(mediaObject: value.media)
            return isToTop
        case .typeScreenTwoColumnSingleSelection(let value):
            let isToTop = isContainerReadyToTopAlignmentWith(mediaObject: value.media)
            return isToTop
        case .typeScreenTableMultipleSelection(let value):
            let isToTop = isContainerReadyToTopAlignmentWith(mediaObject: value.media)
            return isToTop
        case .typeScreenTableSingleSelection(let value):
            let isToTop = isContainerReadyToTopAlignmentWith(mediaObject: value.media)
            return isToTop
        default:
            return false
        }
    }
    
    func isContainerReadyToTopAlignmentWith(mediaObject: Media?) -> Bool {
        if let media = mediaObject {
            if media.styles.topAlignment == nil {
                return true
            } else {
                if let alignment = media.styles.topAlignment, alignment == .top {
                    return true
                } else {
                    return false
                }
            }
        } else {
            return false
        }
    }
    
    func containerTillLeftRightParentView() -> Bool  {
        switch self._struct {
        case .typeScreenTwoColumnMultipleSelection(let value):
            let isLeftRight = isContainerTillLeftRightParentView(mediaObject: value.media)
            return isLeftRight
        case .typeScreenTwoColumnSingleSelection(let value):
            let isLeftRight = isContainerTillLeftRightParentView(mediaObject: value.media)
            return isLeftRight
        case .typeScreenTableMultipleSelection(let value):
            let isLeftRight = isContainerTillLeftRightParentView(mediaObject: value.media)
            return isLeftRight
        case .typeScreenTableSingleSelection(let value):
            let isLeftRight = isContainerTillLeftRightParentView(mediaObject: value.media)
            return isLeftRight
        default:
            return false
        }
    }
    
    func isContainerTillLeftRightParentView(mediaObject: Media?) -> Bool {
        if let media = mediaObject {
            if media.styles.topAlignment == .navigationbar {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
}

extension ScreensGraph {
    
    func allPurchaseProductIds() -> Set<String> {
        var ids = [String]()
        let paywalls = self.screens.compactMap({ $0.value.paywallScreenValue()?.subscriptions.items })
       
        for items in paywalls {
            let oneScreenIds = items.compactMap({$0.subscriptionId})
            ids.append(contentsOf: oneScreenIds)
        }
        
        let setIds = Set(ids.map({$0}))

        return setIds
    }

}

extension ItemTypeSubscription {
    
    func isTwoLabelInAnyColumn() -> Bool {
        let is2NonEmptyLabelsLeftColumn = !self.leftLabelTop.textByLocale().isEmpty && !self.leftLabelBottom.textByLocale().isEmpty
        let is2NonEmptyLabelsRightColumn = !self.rightLabelTop.textByLocale().isEmpty && !self.rightLabelBottom.textByLocale().isEmpty
        if is2NonEmptyLabelsLeftColumn || is2NonEmptyLabelsRightColumn {
            return true
        } else {
            return false
        }
    }
    
    func isLeftColumnEmpty() -> Bool {
        let isEmpty = self.leftLabelTop.textByLocale().isEmpty && self.leftLabelBottom.textByLocale().isEmpty
        return isEmpty
    }
    
    func isRightColumnEmpty() -> Bool {
        let isEmpty = self.rightLabelTop.textByLocale().isEmpty && self.rightLabelBottom.textByLocale().isEmpty
        return isEmpty
    }
    
    func isOneColumn() -> Bool {
        if isLeftColumnEmpty() || isRightColumnEmpty() {
            return true
        }
        return false
    }
    
}
