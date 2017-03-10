//
//  SignUpViewController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-03-10.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController {
    
    // Firebase References
    private lazy var userInformationRef: FIRDatabaseReference = FIRDatabase.database().reference().child("userInformation")
    private lazy var registeredUsernamesRef: FIRDatabaseReference = FIRDatabase.database().reference().child("registeredUsernames")

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // ==========================================
    // ==========================================
    @IBAction func didTapCreateAccount(_ sender: Any) {
        
        if (emailTextField.text == "" || usernameTextField.text! == "" || firstNameTextField.text == "" || lastNameTextField.text == "" || passwordTextField.text == "") {
            
            // Alert user that there are missing fields
            let ac = UIAlertController(title: "Missing Fields", message: "Please fill in all required information", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            // Present alert, escape function
            self.present(ac, animated: true)
            return
            
        }
        
        // Make sure all important info is provided, then store
        guard let email = emailTextField.text,
            let password = passwordTextField.text,
            let firstName = firstNameTextField.text,
            let lastName = lastNameTextField.text
        else { return }
        
        let username = (self.usernameTextField.text == nil) ? email.components(separatedBy: "@")[0] : self.usernameTextField.text!
        
        
        // ERROR CASE 1: Weak password
        if (password.characters.count < 6) {
            
            // Alert user that their password needs to be stronger
            let ac = UIAlertController(title: "Password Is Too Weak", message: "Your password must be 6 or more characters.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            // Present alert, then shift focus to password field
            self.present(ac, animated: true) { self.passwordTextField.becomeFirstResponder() }
            return
        }
        
        // ERROR CASE 2: Improper username specified at signup
        // TODO: Look into restrictions on <FIRDataSnapshot>.hasChild() which will affect valid usernames
        if (username.characters.count < 4 || username.contains(" ")) {
            
            // Alert user that their username needs to be better
            let ac = UIAlertController(title: "Username is Invalid", message: "Your username must be 4 or more valid characters", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            // Present alert, then shift focus to username field
            self.present(ac, animated: true) { self.usernameTextField.becomeFirstResponder() }
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
                    // All fields are accounted for, displayName defaults to username
                    let userEntry = [
                        "displayName" : username,
                        "email" : email,
                        "firstName" : firstName,
                        "lastName" : lastName,
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
                    self.setAccountDetails(user!, username, firstName, lastName)
                    self.attemptLogin(withEmail: email, andPassword: password)
                    
                }
                
                
            } else {
                
                // ERROR CASE 3: Username was already taken
                // Alert user that username already exists, shift focus to username field
                let ac = UIAlertController(title: "Username Already Taken", message: "Please choose another username.", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(ac, animated: true) { self.usernameTextField.becomeFirstResponder() }
            }
        })
    }
    
    // ==========================================
    // ==========================================
    private func attemptLogin(withEmail email: String, andPassword password: String) {
        
        // Let the auth object sign in the user with given credentials
        FIRAuth.auth()?.signIn(withEmail: email, password: password) { (user, error) in
            
            // In the case of invalid login, handle gracefully
            if let error = error {
                print(error.localizedDescription);
                
                // Let user know that email/password is invalid
                let ac = UIAlertController(title: "Invalid Login", message: "Please double check your email and password.", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(ac, animated: true, completion: nil)
                
                // TODO: Handle seemingly impossible case of failed login after account creation
                print("<<<< AT.ME::DEBUG >>>>: Login attempt unsuccessful, however account was created")
                return
            }
            
            // At this point, sign in was successful, so perform segue
            print("<<<< AT.ME::DEBUG >>>>: Login attempt successful, now signed in as currentUser and performing segue")
            self.performSegue(withIdentifier: Constants.Segues.signUpSuccessSegue, sender: nil)
        }
    }
    
    
    // MARK: Firebase Config
    // ==========================================
    // ==========================================
    func setAccountDetails(_ user: FIRUser?, _ username: String, _ firstName: String, _ lastName: String) {
        
        // Obtain an object (change request) to change details of account
        let changeRequest = user?.profileChangeRequest()
        
        // Change display name, then commit changes
        changeRequest?.displayName = user?.email!.components(separatedBy: "@")[0]
        changeRequest?.commitChanges() { (error) in
            
            if let error = error { print("<<<< AT.ME::DEBUG >>>>: \(error.localizedDescription)"); return }
        }
    }
    
    // ==========================================
    // Go back (dismiss) to sign in controller
    // ==========================================
    @IBAction func transitionToSignIn(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
}
