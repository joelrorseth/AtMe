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
    
    // ==========================================
    // ==========================================
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Important: Set delegate of the custom UIView
        let promptView = PromptView(frame: self.view.frame)
        
        promptView.promptDelegate = self
        promptView.changingAttribute = changingAttribute
        promptView.setLabel(label: changingAttributeName)
        
        self.view.addSubview(promptView)
    }
    
    // ==========================================
    // ==========================================
    func changeEmail(email: String, callback: @escaping (Bool, Error?) -> Void) {
        
        Auth.auth().currentUser?.updateEmail(to: email, completion: { error in
            
            if let error = error {
                print("Error changing email: \(error.localizedDescription)")
                callback(false, error)
            
            } else { callback(true, error) }
        })
    }
    
    /**
     Attempt to change the current user's password
     - parameters:
        - password: The new password requested
        - callback: Callback function that is called when Auth confirms it can or cannot perform change
            - error: An optional Error object that will hold information if and when request fails
     */
    func changePassword(password: String, callback: @escaping (Error?) -> Void) {
        
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
        
        if (changingAttribute == .email) {
            changeEmail(email: value, callback: { (success, error) in
                
                if (!success) {
                    self.view.isHidden = true

                    var message: String
                    
                    // Unwrap the error message or give it a general one if N/A
                    if let error = error { message = error.localizedDescription }
                    else { message = Constants.Errors.changeEmailError}

                    // Present the alert, and dismiss this whole view when OK is pressed
                    self.presentSimpleAlert(title: "Error changing email address", message: message, completion: { _ in
                        self.dismiss(animated: true, completion: nil)
                    })
                }
            })
            
            return
            
        } else if (changingAttribute == .password) {
            
            changePassword(password: value, callback: { error in
                self.view.isHidden = true
                
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
        }
        
        // Normal changes are written directly to user record in Firebase
        // TODO: Implement checking to enforce rules on certain attributes
        // TODO: Save attribute into UserState.currentUser
        
        if let user = Auth.auth().currentUser {
            userInformationRef.child(String(user.uid)).child("\(changingAttribute)").setValue(value)
        }
        
        //print("Commiting value: \(value) for key \(changingAttribute)")
        //self.dismiss(animated: true, completion: nil)
    }
    
    // ==========================================
    // ==========================================
    func didCancelChange() {
        self.dismiss(animated: true, completion: nil)
    }
}
