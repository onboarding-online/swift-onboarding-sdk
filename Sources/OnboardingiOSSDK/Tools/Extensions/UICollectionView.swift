//
//  UICollectionView.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 17.05.2023.
//

import UIKit

extension UICollectionView {
    
    func registerCellNibOfType<T: UICollectionViewCell>(_ type: T.Type) {
        registerCellOfType(type, nibName: String(describing: type))
    }
    
    func registerCellOfType<T: UICollectionViewCell>(_ type: T.Type, nibName: String) {
        let reuseIdentifier = String(describing: type)
        register(UINib(nibName: nibName, bundle: .module), forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    func dequeueCellOfType<T: UICollectionViewCell>(_ type: T.Type, forIndexPath indexPath: IndexPath) -> T {
        self.dequeueCellOfType(type, withIdentifier: String(describing: T.self), forIndexPath: indexPath)
    }
    
    func dequeueCellOfType<T: UICollectionViewCell>(_ type: T.Type, withIdentifier identifier: String, forIndexPath indexPath: IndexPath) -> T {
        self.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! T
    }
    
}
