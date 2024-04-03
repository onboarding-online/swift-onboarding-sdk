//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 26.12.2023.
//

import UIKit

enum GradientDirection {
    case topToBottom, bottomToTop,leftToRight, topLeftToBottomRight, topRightToBottomLeft
}

class GradientView: UIView {
    
    var gradientColors = [UIColor]() { didSet { updateAppearence() } }
    var gradientDirection: GradientDirection = .topToBottom
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        baseInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        baseInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateAppearence()
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        
        updateAppearence()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateAppearence()
    }
    
}

// MARK: - Setup methods
private extension GradientView {
    func baseInit() {
        layer.masksToBounds = false
        clipsToBounds = false
        backgroundColor = .clear
        updateAppearence()
    }
    
    func updateAppearence() {
        setBackgroundGradientWithColors(gradientColors, radius: 0, gradientDirection: gradientDirection)
    }
}

extension UIView {
    func setBackgroundGradientWithColors(_ colors: [UIColor], radius: CGFloat = 12, corner: UIRectCorner = .allCorners, gradientDirection: GradientDirection = .topToBottom) {
        if let gradientSublayers = layer.sublayers?.filter({ $0.name == "gradientSublayer" }) {
            for sublayer in gradientSublayers {
                sublayer.removeFromSuperlayer()
            }
        }
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = colors.map({ $0.cgColor })
        switch gradientDirection {
        case .topToBottom:
            gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
            gradient.endPoint = CGPoint(x: 0.0, y: 1.0)
        case .leftToRight:
            gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        case .topLeftToBottomRight:
            gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
            gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        case .topRightToBottomLeft:
            gradient.startPoint = CGPoint(x: 1.0, y: 0.0)
            gradient.endPoint = CGPoint(x: 0.0, y: 1.0)
        case .bottomToTop:
            gradient.endPoint = CGPoint(x: 0.0, y: 0.0)
            gradient.startPoint = CGPoint(x: 0.0, y: 1.0)
        }
        
        gradient.name = "gradientSublayer"
        let shape = CAShapeLayer()
        shape.path = UIBezierPath(roundedRect: gradient.bounds,
                                  byRoundingCorners: corner,
                                  cornerRadii: CGSize(width: radius, height: radius)).cgPath
        gradient.mask = shape
        layer.insertSublayer(gradient, at: 0)
    }
}
