//
//  OboardingsModelExtentionsTemp.swift
//  OnboardingOnline
//
//  Created by Leonid Yuriev on 16.02.23.
//

import Foundation
import UIKit
import ScreensGraph

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

extension OnboardingLocalVideoAssetProvider {
    
    func urlToVideoAsset() async -> URL? {
        let urlByLocale = assetUrlByLocale()
        if let name = urlByLocale?.assetName {
            if let videoURL = Bundle.main.url(forResource: name, withExtension: "mp4") {
                return videoURL
            }
        }
        
        guard let stringURL = urlByLocale?.assetUrl?.origin else {
            return nil
        }
        
        if let name = stringURL.resourceNameWithoutExtension() {
            if let videoURL = Bundle.main.url(forResource: name, withExtension: "mp4") {
                return videoURL
            }
        }
        
        if let name = stringURL.resourceName() {
            if let videoURL = Bundle.main.url(forResource: name, withExtension: nil) {
                return videoURL
            }
        }
        
        let _ = await AssetsLoadingService.shared.loadData(from: stringURL, assetType: .video)
        if let storedURL = AssetsLoadingService.shared.urlToStoredData(from: stringURL, assetType: .video) {
            return storedURL
        } else if let url = URL(string: stringURL) {
            return url
        }
        return nil
    }
}

extension BaseVideo: OnboardingLocalVideoAssetProvider { }

protocol OnboardingLocalImageAssetProvider: OnboardingLocalAssetProvider { }

extension OnboardingLocalImageAssetProvider {
   
    func loadImage() async -> UIImage? {
        let urlByLocale = assetUrlByLocale()

        if let assetName = urlByLocale?.assetName,
            let image = UIImage.init(named: assetName) {
            return image
        } else if let url = urlByLocale?.assetUrl?.origin {
            // Check local resources first
            if let imageName = url.resourceName(),
               let image = await UIImage.createWith(name: imageName) {
                return image
            }
            
            return await AssetsLoadingService.shared.loadImage(from: url)
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

extension BaseImage: OnboardingLocalImageAssetProvider { }

extension BaseText {
    
    func textByLocale() -> String {
        let valueByLocale = LocaleHelper.valueByLocaleFor(dict: l10n, defaultLanguage: OnboardingService.shared.screenGraph?.defaultLanguage.rawValue)
        
        return valueByLocale
    }
    
    func textColor() -> UIColor {
        return (self.styles.color ?? "#FFFFFF").hexStringToColor
    }
    
}

extension Text {
    
    func textByLocale() -> String {
        let valueByLocale = LocaleHelper.valueByLocaleFor(dict: l10n, defaultLanguage: OnboardingService.shared.screenGraph?.defaultLanguage.rawValue)
        
        return valueByLocale
    }
    
    func textFor(product: StoreKitProduct) -> String {
        var text = self.textByLocale()
        
        let trialDescription = product.subscriptionDescription?.trialDescription?.trialFullDescription ?? ""
        let price = product.localizedPrice
        let duration = product.subscriptionDescription?.periodLocalizedUnitName ?? ""
        
        let pricePerPeriod = "\(price) per \(duration)"
        
        let dict = ["@trialDuration": trialDescription, "@pricePerDuration" : pricePerPeriod]
        
        for key in dict.keys {
            if let value = dict[key] {
                text =  text.replacingOccurrences(of: key, with: value)
            }
        }
        
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
    
    
    func textHeightBy(textWidth: CGFloat) -> CGFloat {
        let labelKey = self.textByLocale()
        let font: UIFont = self.textFont()
        
        let constraintRect = CGSize(width: textWidth, height: .greatestFiniteMagnitude)
        let boundingBox = labelKey.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return ceil(boundingBox.height)
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
            imageName = isSelected ? "Circle_on" : "Circle_off"
        case .square:
            imageName = isSelected ? "Square_Rounded_on" : "Square_Rounded_off"
        }
        
        if let image = UIImage.init(named: "\(imageName).png", in: .module, with: nil) {
            self.image = image.withRenderingMode(.alwaysTemplate)
            let tintColor = isSelected ? checkbox.selectedBlock.styles.color : checkbox.styles.color
            
            self.tintColor = tintColor?.hexStringToColor
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
        
        self.apply(text: text.styles)
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
        self.layer.borderColor = (button.styles.borderColor ?? "").hexStringToColor.cgColor
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
        
        self.placeholder = text.textByLocale()
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
        case .typeScreenBasicPaywall(_), .typeScreenScalableImageTextSelection(_):
            return ValueTypes.none
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
    
}
