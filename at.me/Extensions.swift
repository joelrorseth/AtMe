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
    
    // ==========================================
    // ==========================================
    func presentPhotoSelectionPrompt(completion: ((UIImagePickerControllerSourceType) -> Void)?) {
        
        let controller = UIAlertController(title: "Change Profile Picture", message: "Where do you want to take your picture?", preferredStyle: UIAlertControllerStyle.actionSheet)

        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
            controller.addAction(UIAlertAction(title: "Camera", style: UIAlertActionStyle.default, handler: { _ in
 
                completion!(UIImagePickerControllerSourceType.camera)
            }))
        }
        
        controller.addAction(UIAlertAction(title: "Photo Library", style: UIAlertActionStyle.default, handler: { _ in
            completion!(UIImagePickerControllerSourceType.photoLibrary)
        }))
        
        controller.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        self.present(controller, animated: true, completion: nil)
        
    }
}
