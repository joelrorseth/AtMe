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
    
    // Firebase references
    private lazy var userInformationRef: FIRDatabaseReference = FIRDatabase.database().reference().child("userInformation")
    private lazy var registeredUsernamesRef: FIRDatabaseReference = FIRDatabase.database().reference().child("registeredUsernames")
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    // MARK: Buttons
    // ==========================================
    // ==========================================
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
                
                print("<<<< AT.ME::DEBUG >>>>: Login unsuccessful")
                return
            }
            
            print("<<<< AT.ME::DEBUG >>>>: Login successful")
            self.performSegue(withIdentifier: "showChatList", sender: nil)
        }
    }
    
    // ==========================================
    // ==========================================
    @IBAction func didTapSignUp(_ sender: Any) {
        
        // Make sure all important info is provided, then store
        guard let email = emailField.text, let password = passwordField.text else { return }
        let username = (self.usernameField.text == nil) ? email.components(separatedBy: "@")[0] : self.usernameField.text!

        
        
        // ERROR CASE 1: Weak password
        if (password.characters.count < 6) {
            
            // Alert user that their password needs to be stronger
            let ac = UIAlertController(title: "Password Is Too Weak", message: "Your password must be 6 or more characters.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            // Present alert, then shift focus to password field
            self.present(ac, animated: true) { self.passwordField.becomeFirstResponder() }
            return
        }
        
        // ERROR CASE 2: Improper username specified at signup
        // TODO: Look into restrictions on <FIRDataSnapshot>.hasChild() which will affect valid usernames
        if (username.characters.count < 4 || username.contains(" ")) {
            
            // Alert user that their username needs to be better
            let ac = UIAlertController(title: "Username is Invalid", message: "Your username must be 4 or more valid characters", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            // Present alert, then shift focus to username field
            self.present(ac, animated: true) { self.usernameField.becomeFirstResponder() }
            return
        }
        
        
        // Take snapshot of databse to check for existing username
        registeredUsernamesRef.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            
            // If username is not found, we are OK to create account
            if (!snapshot.hasChild(username)) {
                
                
                // Let the auth object create a user with given fields
                FIRAuth.auth()?.createUser(withEmail: email, password: password) { (user, error) in
                    
                    
                    // ERROR CASE 2: Any other error (Email taken)
                    if let error = error {
                        print("<<<< AT.ME::DEBUG >>>>: \(error.localizedDescription)")
                        return
                    }
                    
                    // Add entry to database with public user information (username, email)
                    // TODO: Link up text fields for name, display name etc in a separate controller
                    let userEntry = [
                        "displayName" : username,
                        "email" : email,
                        "firstName" : "FNAME",
                        "lastName" : "LNAME",
                        "username" : username,
                    ]
                    
                    
                    // Add entry to usernames registry and user info registry
                    self.registeredUsernamesRef.child(username).setValue((user?.uid)!)
                    self.userInformationRef.child((user?.uid)!).setValue(userEntry)
                    
                    // Update any <FIRUser> properties maintained internally by Firebase
                    let changeRequest = user?.profileChangeRequest()
                    changeRequest?.displayName = username
                    
                    
                    // First time use, set up user name then log into app
                    print("<<<< AT.ME::DEBUG >>>>:: New user creation successful")
                    self.setAccountDetails(user!)
                    self.didTapSignIn(self)
                }
 
                
            } else {
                
                // ERROR CASE 3: Username was already taken
                // Alert user that username already exists, shift focus to username field
                let ac = UIAlertController(title: "Username Already Taken", message: "Please choose another username.", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(ac, animated: true) { self.usernameField.becomeFirstResponder() }
            }
        })
    }
    
    
    // MARK: View
    // ==========================================
    // ==========================================
    override func viewDidAppear(_ animated: Bool) {
        
//        if let _ = FIRAuth.auth()?.currentUser {
//            print("<<<< AT.ME::DEBUG >>>>: Login Successful")
//            self.performSegue(withIdentifier: "showChatList", sender: nil)
//        }
    }
    
    
    // MARK: Firebase Config
    // ==========================================
    // ==========================================
    func setAccountDetails(_ user: FIRUser?) {
        
        // Obtain an object (change request) to change details of account
        let changeRequest = user?.profileChangeRequest()
        
        // Change display name, then commit changes
        changeRequest?.displayName = user?.email!.components(separatedBy: "@")[0]
        changeRequest?.commitChanges() { (error) in
            
            if let error = error { print("<<<< AT.ME::DEBUG >>>>: \(error.localizedDescription)"); return }
        }
    }
}
