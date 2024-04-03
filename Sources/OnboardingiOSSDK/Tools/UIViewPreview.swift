//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 27.12.2023.
//

import SwiftUI

struct UIViewPreview<T: UIView>: UIViewRepresentable {
    
    let view: T
    
    init(_ viewBuilder: @escaping () -> T) {
        view = viewBuilder()
    }
    
    // MARK: - UIViewRepresentable
    func makeUIView(context: Context) -> T {
        return view
    }
    
    func updateUIView(_ view: T, context: Context) {
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
    }
}

/*
 Usage
 
 struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview {
            MyView()
        }
    }
 }
 
 */
