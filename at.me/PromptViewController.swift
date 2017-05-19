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
    lazy var userInformationRef: FIRDatabaseReference = FIRDatabase.database().reference().child("userInformation")
    
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
    func changeEmail(email: String, callback: ((Void) -> ())?) {
        
        FIRAuth.auth()?.currentUser?.updateEmail(email, completion: { (error) in
            if let error = error {
                
                print("at.me:: Error changing email: \(error.localizedDescription)")
                self.presentSimpleAlert(title: "Error changing email", message: "Please enter a valid email", completion: nil)
                
                callback?()
                return
            }
            
            callback?()
        })
    }
    
    // ==========================================
    // ==========================================
    func changePassword(password: String, callback: ((Void) -> ())?) {
        
        FIRAuth.auth()?.currentUser?.updatePassword(password, completion: { (error) in
            if let error = error {
                
                // TODO: Not working
                print("at.me:: Error changing password: \(error.localizedDescription)")
                self.presentSimpleAlert(title: "Error changing password", message: "Please try another password", completion: nil)
                
                callback?()
                return
            }
            
            callback?()
        })
    }
}

extension PromptViewController: PromptViewDelegate {
    
    // ==========================================
    // ==========================================
    func didCommitChange(value: String) {
        
        if (changingAttribute == .email) {
            // Allow fallthrough here, email is recorded in user record also
            changeEmail(email: value, callback: {
                self.dismiss(animated: true, completion: nil)
            })
            
        } else if (changingAttribute == .password) {
            changePassword(password: value, callback: {
                self.dismiss(animated: true, completion: nil)
            })
            return
        }
        
        // Normal changes are written directly to user record in Firebase
        // TODO: Implement checking to enforce rules on certain attributes
        // TODO: Save attribute into UserState.currentUser
        
        if let user = FIRAuth.auth()?.currentUser {
            userInformationRef.child(String(user.uid)).child("\(changingAttribute)").setValue(value)
        }
        
        print("Commiting value: \(value) for key \(changingAttribute)")
        self.dismiss(animated: true, completion: nil)
    }
    
    // ==========================================
    // ==========================================
    func didCancelChange() {
        self.dismiss(animated: true, completion: nil)
    }
}
