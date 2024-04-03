//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 27.12.2023.
//

import SwiftUI

/// To preview devices who's max supported iOS version below 17.0
struct UIViewControllerPreview: UIViewControllerRepresentable {
    let viewControllerBuilder: () -> UIViewController
    
    init(_ viewControllerBuilder: @escaping () -> UIViewController) {
        self.viewControllerBuilder = viewControllerBuilder
    }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        return viewControllerBuilder()
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // Not needed
    }
}

/*
 Usage
 
 struct MyVCPreviews: PreviewProvider {
     static var previews: some View {
         UIViewControllerPreview {
             MyVC.nibInstance() <- Instantiate my VC here
         }
         .edgesIgnoringSafeArea(.all)
     }
 }
 */
