//
//  Extensions.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-05-10.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

protocol AlertController{}
extension AlertController where Self:UIViewController {
    
    // ==========================================
    // ==========================================
    func presentSimpleAlert(title: String, message: String, completion: (() -> Void)?) {
        
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // UIAlertController must be presented by the calling controller (self)
        self.present(controller, animated: true, completion: completion)
    }
}

extension ConvoViewController: UICollectionViewDelegate {
    
    // ==========================================
    // ==========================================
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // ==========================================
    // ==========================================
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    // ==========================================
    // ==========================================
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(8, 0, 0, 0)
    }
}
