//
//  File.swift
//  
//
//  Copyright 2023 Onboarding.online on 18.03.2023.
//

import UIKit

extension UITableView {
    
    func registerCellNibOfType<T: UITableViewCell>(_ type: T.Type) {
        let cellName = type.className
        register(UINib(nibName: cellName, bundle: nil), forCellReuseIdentifier: cellName)
    }
    
    func dequeueCellOfType<T: UITableViewCell>(_ type: T.Type) -> T {
        return self.dequeueReusableCell(withIdentifier: type.cellIdentifier) as! T
    }
    
}

