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
