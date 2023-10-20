//
//  File.swift
//  
//
//  Copyright 2023 Onboarding.online on 17.03.2023.
//

import UIKit



extension String {
    
    public func trimHTMLTags() -> String? {
        guard let htmlStringData = self.data(using: String.Encoding.utf8) else {
            return nil
        }
    
        let options: [NSAttributedString.DocumentReadingOptionKey : Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
    
        let attributedString = try? NSAttributedString(data: htmlStringData, options: options, documentAttributes: nil)
        return attributedString?.string
    }
    
    
    func withoutHtmlTags() -> String {
        let str = self.replacingOccurrences(of: "<style>[^>]+</style>", with: "", options: .regularExpression, range: nil)
        return str.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
    
    
    
    func resourceName() -> String? {
        if let cleanStringWithoutParams = self.components(separatedBy: "?").first {
            if let imageString = cleanStringWithoutParams.components(separatedBy: "/").last {
                return imageString
            }
        }
        
        return nil
    }
    
    func resourceNameWithoutExtension() -> String? {
        guard let resourceWithExtension = self.resourceName() else {
            return nil
        }
        if let justName = resourceWithExtension.components(separatedBy: ".").first {
            return justName
        }
        
        return nil
    }
    
    var hexStringToColor: UIColor {
        return UIColor.hexStringToUIColor(hex: self)
    }
    
    var dateFromISO8601String: Date? {
        return ISO8601DateFormatter().date(from: self)
    }
    
    var intArray: [Int]? {
        let stringValues = self.components(separatedBy: ",")
        let intValues = stringValues.compactMap { Int($0) }
        
        return intValues
    }
    
    var nsString: NSString {
        return self as NSString
    }
    
    var fileURL: URL {
        return URL(fileURLWithPath: self)
    }
    
    var doubleValue: Double? {
        if self.contains(",") {
            let replacedComma = self.replacingOccurrences(of: ",", with: ".")
            return Double(replacedComma)
        }
        return Double(self)
    }
    
    var intValue: Int? {
        return Int(self)
    }
    
    var floatValue: Float? {
        return Float(self)
    }
    
    var intValue16: Int16? {
        return Int16(self)
    }
    
    var boolValue: Bool {
        Int(self) == 1
    }
    
    func size(font: UIFont) -> CGSize {
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return CGSize(width: ceil(boundingBox.width), height: ceil(boundingBox.height))
    }
    
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
    
    func attributesFor(font: UIFont?,
                       letterSpacing: CGFloat?,
                       underlineStyle: NSUnderlineStyle?,
                       textColor: UIColor?,
                       alignment: NSTextAlignment?,
                       lineHeight: CGFloat?) -> [NSAttributedString.Key: Any] {
        
        let textColorToUse: UIColor = textColor ??  .black
        var attributes: [NSAttributedString.Key: Any] = [.foregroundColor: textColorToUse]
        if let font = font {
            attributes[.font] = font
        }
        
        if let letterSpacing = letterSpacing {
            attributes[.kern] = letterSpacing
        }
        if let underlineStyle = underlineStyle {
            attributes[.underlineStyle] = underlineStyle.rawValue
        }
        let paragraphStyle = NSMutableParagraphStyle()
        if let alignment = alignment {
            paragraphStyle.alignment = alignment
        }
        if let lineHeight = lineHeight {
            paragraphStyle.minimumLineHeight = lineHeight
            paragraphStyle.maximumLineHeight = lineHeight
        }
        if alignment != nil || lineHeight != nil {
            attributes[.paragraphStyle] = paragraphStyle
        }
        
        return attributes
    }
    
    
}
