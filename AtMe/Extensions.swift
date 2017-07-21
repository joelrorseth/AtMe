//
//  Extensions.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-05-10.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Photos

protocol AlertController{}
extension AlertController where Self:UIViewController {
    
    /**
     Present a simple alert message with an OK button
     - parameters:
     - title: Title of alert
     - message: Message to print in the alert
     - completion: A callback that will be triggered when the user *presses 'OK'*
        - action: The UIAlertAction object passed in the handler for UIAlertAction's initializer
     */
    func presentSimpleAlert(title: String, message: String, completion: ((UIAlertAction) -> Void)?) {
        
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        controller.view.tintColor = Constants.Colors.primaryDark
        controller.addAction(UIAlertAction(title: "OK", style: .default, handler: completion))
        
        // UIAlertController must be presented by the calling controller (self)
        self.present(controller, animated: true, completion: nil)
    }
    
    
    /** Presents a UIAlertController to prompt for location to choose asset from. 
     - parameters:
        - completion: A completion callback which fires when a UIAlertAction is trigger via selecting an option on the UIAlertController
     */
    func presentPhotoSelectionPrompt(completion: ((UIImagePickerControllerSourceType) -> Void)?) {
        
        let controller = UIAlertController(title: "Change Profile Picture", message: "Where do you want to take your picture?", preferredStyle: UIAlertControllerStyle.actionSheet)
        controller.view.tintColor = Constants.Colors.primaryDark

        // Add camera option (if available)
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
            controller.addAction(UIAlertAction(title: "Camera", style: UIAlertActionStyle.default, handler: { _ in
 
                completion!(UIImagePickerControllerSourceType.camera)
            }))
        }
        
        // Add photo library option
        controller.addAction(UIAlertAction(title: "Photo Library", style: UIAlertActionStyle.default, handler: { _ in
            completion!(UIImagePickerControllerSourceType.photoLibrary)
        }))
        
        // Present the action sheet
        controller.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(controller, animated: true, completion: nil)
    }
}

extension UIImage {
    
    /** Create a 1x1 image consisting of a given color. 
     - parameters:
        color: The UIColor object to populate the UIImage with
     */
    static func imageFromColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        
        // Create 1 by 1 pixel context
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        color.setFill()
        UIRectFill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
        
    }
}

extension UIImagePickerControllerDelegate {
    
    /** Convert a UIImage into a Data object, if possible. 
     - parameters:
        image: The UIImage to convert
     */
    func convertImageToData(image: UIImage) -> Data? {
        return UIImageJPEGRepresentation(image, 0.8)
    }
}

extension UIViewController {
    
    /** Render a CAGradientLayer gradient using the app's two primary colors. */
    func renderGradientLayer() -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.frame = UIScreen.main.bounds
        gradient.colors = [Constants.Colors.primaryDark.cgColor, Constants.Colors.primaryLight.cgColor]
        return gradient
    }
}
