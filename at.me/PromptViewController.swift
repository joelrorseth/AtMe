//
//  PromptViewController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-05-14.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase

class PromptViewController: UIViewController, AlertController {
    
    // Firebase references
    lazy var userInformationRef: DatabaseReference = Database.database().reference().child("userInformation")
    
    var promptDelegate: PromptViewDelegate?
    var changingAttribute: Constants.UserAttribute = .none
    var changingAttributeName: String = ""
    
    
    /**
     A function called right before the view lays out its subviews
     */
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Important: Set delegate of the custom UIView
        let promptView = PromptView(frame: self.view.frame)
        
        promptView.promptDelegate = self
        promptView.changingAttribute = changingAttribute
        promptView.setLabel(label: changingAttributeName)
        
        self.view.addSubview(promptView)
    }
    

    /**
     Attempt to change the current user's email, update database and device records accordingly
     - parameters:
        - email: The new email requested
        - callback: Callback function that is called when Auth confirms it can or cannot perform change
            - error: An optional Error object that will hold information if and when request fails
     */
    func changeEmail(email: String, callback: @escaping (Error?) -> Void) {
        
        // Use the Firebase Auth function to allow changes to internal auth records
        Auth.auth().currentUser?.updateEmail(to: email, completion: { error in
            
            if let error = error {
                print("Error changing email: \(error.localizedDescription)")
                callback(error)
            
            } else {
                
                // Update local and database email records, then callback
                self.userInformationRef.child(UserState.currentUser.uid).child("email").setValue(email)
                UserState.currentUser.email = email
                callback(nil)
            }
        })
    }
    
    
    /**
     Attempt to change the current user's password, but will never store or record it directly
     - parameters:
        - password: The new password requested
        - callback: Callback function that is called when Auth confirms it can or cannot perform change
            - error: An optional Error object that will hold information if and when request fails
     */
    func changePassword(password: String, callback: @escaping (Error?) -> Void) {
        
        // Use the Firebase Auth function to allow changes to internal auth records
        Auth.auth().currentUser?.updatePassword(to: password, completion: { error in
            
            if let error = error {
                
                print("Error changing password: \(error.localizedDescription)")
                callback(error)
            
            } else { callback(nil) }
        })
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
            
            // Attempt to change email using dedicated function
            changeEmail(email: value, callback: { error in
                
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
            
            // Attempt to change password using dedicated function
            changePassword(password: value, callback: { error in
                
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
            
            userInformationRef.child(UserState.currentUser.uid).child("\(changingAttribute)").setValue(value)
            self.presentSimpleAlert(title: "Success", message: "Your \(changingAttributeName) has been updated", completion: { _ in
                self.dismiss(animated: true, completion: nil)
            })
        }
    }
    
    
    /**
     User tapped outside of prompt and wants to dismiss it
     */
    func didCancelChange() {
        self.dismiss(animated: true, completion: nil)
    }
}
