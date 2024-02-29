//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 27.12.2023.
//

import UIKit
import ScreensGraph

final class PaywallCheckboxView: UIView {
    
    private var style: Style = .circle
    private var checkmarkLayer: CAShapeLayer?
    var offBorderColor: UIColor? = nil { didSet { updateAppearance() } }
    var isOn: Bool = false { didSet { updateAppearance() }}
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = bounds.width / 2
        updateAppearance()
    }
    
    override var intrinsicContentSize: CGSize {
        .init(width: 20, height: 20)
    }
    
    func apply(checkBox: CheckBox) {
        
    }
    
}

// MARK: - Setup methods
private extension PaywallCheckboxView {
    func setup() {
        tintColor = .systemIndigo
        updateAppearance()
    }
    
    func updateAppearance() {
        if isOn {
            addCheckmark()
            layer.borderWidth = 0
            layer.borderColor = tintColor.cgColor
            backgroundColor = tintColor
        } else {
            removeCheckmark()
            layer.borderWidth = 1
            layer.borderColor = offBorderColor?.cgColor ?? tintColor.cgColor
            backgroundColor = .clear
        }
    }
    
    func removeCheckmark() {
        checkmarkLayer?.removeFromSuperlayer()
        checkmarkLayer = nil
    }
    
    func addCheckmark() {
        removeCheckmark()
        
        let checkmarkLayer = CAShapeLayer()
        self.checkmarkLayer = checkmarkLayer
        
        checkmarkLayer.strokeColor = UIColor.white.cgColor
        checkmarkLayer.fillColor = UIColor.clear.cgColor
        checkmarkLayer.lineCap = .round
        checkmarkLayer.lineWidth = 2.5
        let path = UIBezierPath()
        path.move(to: relativePoint(x: 0.3, y: 0.45))
        path.addLine(to: relativePoint(x: 0.45, y: 0.65))
        path.addLine(to: relativePoint(x: 0.7, y: 0.33))
        checkmarkLayer.path = path.cgPath
        
        layer.addSublayer(checkmarkLayer)
    }
    
    func relativePoint(x: CGFloat, y: CGFloat) -> CGPoint {
        CGPoint(x: bounds.width * x,
                y: bounds.height * y)
    }
}

// MARK: - Open methods
extension PaywallCheckboxView {
    enum Style {
        case circle
    }
}

import SwiftUI
struct PaywallCheckbox_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview {
            let view = PaywallCheckboxView()
            view.isOn = false
            return view
        }
    }
}
