//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 27.12.2023.
//

import UIKit

final class SavedMoneyView: UIView {
    
    var label: UILabel!
    
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
        
//        layer.cornerRadius = bounds.height / 2
    }
    
    override var intrinsicContentSize: CGSize {
        .init(width: 200, height: 24)
    }
}

// MARK: - Setup methods
private extension SavedMoneyView {
    func setup() {
        addLabel()
    }
    
    func addLabel() {
        label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.text = "30% Save"
        label.setContentHuggingPriority(.required, for: .horizontal)
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 7),
            trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 7),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 2.5),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

import SwiftUI
struct SavedMoneyView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview {
            let view = SavedMoneyView()
            return view
        }
    }
}
