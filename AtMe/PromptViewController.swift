//
//  PromptViewController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-05-14.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase

class PromptViewController: UIViewController, AlertController {
  
  var authManager: AuthManager = FirebaseAuthManager.shared
  var userManager: UserManager = FirebaseUserManager.shared
  
  var promptDelegate: PromptViewDelegate?
  var changingAttribute: Constants.UserAttribute = .none
  var changingAttributeName: String = ""
  
  
  /** An overridden method called right before the view lays out its subviews. */
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    
    // Important: Set delegate of the custom UIView
    let promptView = PromptView(frame: self.view.frame)
    
    promptView.promptDelegate = self
    promptView.changingAttribute = changingAttribute
    promptView.setLabel(label: changingAttributeName)
    
    self.view.addSubview(promptView)
  }
}

extension PromptViewController: PromptViewDelegate {
  
  /**
   Fires when the user has tapped the commit button on the prompt, to commit desired change
   - parameters:
   - value: The value present in the text field when commit button was pressed
   */
  func didCommitChange(value: String) {
    self.view.isHidden = true
    
    // Break up possible changes into three possibilities: email, password, or other
    // Email and password change have dedicated function in PromptViewController
    // Other changes only need to directly modify the user's record for that attribute
    
    if (changingAttribute == .email) {
      
      userManager.changeEmailAddress(to: value, completion: { error in
        
        if let error = error {
          self.presentSimpleAlert(title: "Error changing email", message: error.localizedDescription, completion: { _ in
            self.dismiss(animated: true, completion: nil)
          })
          
        } else {
          self.presentSimpleAlert(title: "Success", message: "Your email address has been updated", completion: { _ in
            self.dismiss(animated: true, completion: nil)
          })
        }
      })
      
      return
      
    } else if (changingAttribute == .password) {
      
      userManager.changePassword(password: value, callback: { error in
        
        if let error = error {
          self.presentSimpleAlert(title: "Error changing password", message: error.localizedDescription, completion: { _ in
            self.dismiss(animated: true, completion: nil)
          })
          
        } else {
          self.presentSimpleAlert(title: "Success", message: "Your password has been updated", completion: { _ in
            self.dismiss(animated: true, completion: nil)
          })
        }
      })
      
      return
      
    } else {
      
      // Change the attribute directly if not a password or email
      // This is easy because Auth (Firebase) only internally maintains email and password
      
      userManager.changeCurrentUser(attribute: "\(changingAttribute)", value: value)
      self.presentSimpleAlert(title: "Success", message: "Your \(changingAttributeName) has been updated", completion: { _ in
        self.dismiss(animated: true, completion: nil)
      })
    }
  }
  
  
  /** User tapped outside of prompt and wants to dismiss it. */
  func didCancelChange() {
    self.dismiss(animated: true, completion: nil)
  }
}
