//
//  File.swift
//  
//
//  Copyright 2023 Onboarding.online on 17.03.2023.
//

import UIKit

extension UIView {
    
    func embedInSuperView(_ superView: UIView) {
        self.putInSuperview(superView)
        
        self.leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive = true
        self.trailingAnchor.constraint(equalTo: superView.trailingAnchor).isActive = true
        self.topAnchor.constraint(equalTo: superView.topAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive = true
    }
    
    func putInSuperview(_ view: UIView) {
        view.addSubview(self)
        self.clipsToBounds = true
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func centeredInView(_ view: UIView, offset: CGPoint = .zero) {
        self.putInSuperview(view)
        
        self.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset.x).isActive = true
        self.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: offset.y).isActive = true
        self.widthAnchor.constraint(equalToConstant: self.frame.width).isActive = true
        self.heightAnchor.constraint(equalToConstant: self.frame.height).isActive = true
        view.layoutIfNeeded()
    }
    
    func addConstraintToView(_ view: UIView, attribute: NSLayoutConstraint.Attribute, constant: Double) {
        self.putInSuperview(view)
        
        self.widthAnchor.constraint(equalToConstant: self.frame.width).isActive = true
        self.heightAnchor.constraint(equalToConstant: self.frame.height).isActive = true
        switch attribute {
        case .top:
            self.topAnchor.constraint(equalTo: view.bottomAnchor, constant: constant.cgFloatValue).isActive = true
            self.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        case .bottom:
            self.bottomAnchor.constraint(equalTo: view.topAnchor, constant: constant.cgFloatValue).isActive = true
            self.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        default:
            self.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            self.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        }
    }
    
    var localCenter: CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
}

// MARK: - Open methods
extension UIView {
    func applyFigmaShadow(x: CGFloat = 0,
                          y: CGFloat = 2,
                          blur: CGFloat = 4,
                          spread: CGFloat = 0,
                          color: UIColor = .black,
                          alpha: Float = 0.2) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = alpha
        layer.shadowOffset = CGSize(width: x, height: y)
        layer.shadowRadius = blur / 2
        if self is UILabel {
            return
        }
        if spread == 0 {
            layer.shadowPath = nil
        } else {
            let dx = -spread
            let rect = bounds.insetBy(dx: dx, dy: dx)
            layer.shadowPath = UIBezierPath(roundedRect: rect, cornerRadius: layer.cornerRadius).cgPath
        }
    }
}
