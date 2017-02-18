//
//  SignInViewController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-02-18.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase

class SignInViewController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    // MARK: Buttons
    @IBAction func didTapSignIn(_ sender: Any) {
        
        guard let email = emailField.text, let password = passwordField.text else { return }
        
        // Let the auth object sign in the user with given credentials
        FIRAuth.auth()?.signIn(withEmail: email, password: password) { (user, error) in
            
            // In the case of invalid login, handle gracefully
            if let error = error {
                print(error.localizedDescription);
                
                // Let user know that email/password is invalid
                let ac = UIAlertController(title: "Invalid Login", message: "Please double check your email and password.", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(ac, animated: true, completion: nil)
                
                return
            }
            
            print("at.me:: Login successful")
            self.performSegue(withIdentifier: "showChatList", sender: nil)
        }
    }
    
    // ==========================================
    // ==========================================
    @IBAction func didTapSignUp(_ sender: Any) {
        
        guard let email = emailField.text, let password = passwordField.text else { return }
        
        // Check for weak password
        if (password.characters.count < 6) {
            
            // Alert user that their password needs to be stronger
            let ac = UIAlertController(title: "Password Is Too Weak", message: "Your password must be 6 or more characters.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(ac, animated: true, completion: nil)
            
            return
        }
        
        // Let the auth object create a user with given fields
        FIRAuth.auth()?.createUser(withEmail: email, password: password) { (user, error) in
            if let error = error { print(error.localizedDescription); return }
            
            // First time use, set up user name
            print("at.me:: Created user successfully")
            self.setAccountDetails(user!)
        }
    }
    
    // ==========================================
    // ==========================================
    override func viewDidAppear(_ animated: Bool) {
        
        if let _ = FIRAuth.auth()?.currentUser {
            print("at.me:: Login successful")
            self.performSegue(withIdentifier: "showChatList", sender: nil)
        }
    }
    
    // ==========================================
    // ==========================================
    func setAccountDetails(_ user: FIRUser?) {
        
        // Obtain an object (change request) to change details of account
        let changeRequest = user?.profileChangeRequest()
        
        // Change display name, then commit changes
        changeRequest?.displayName = user?.email!.components(separatedBy: "@")[0]
        changeRequest?.commitChanges() { (error) in
            
            if let error = error { print(error.localizedDescription); return }
        }
    }
}
