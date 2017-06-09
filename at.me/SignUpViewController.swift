//
//  SignUpViewController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-03-10.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController, AlertController {
    
    // Firebase References
    private lazy var userInformationRef: FIRDatabaseReference = FIRDatabase.database().reference().child("userInformation")
    private lazy var registeredUsernamesRef: FIRDatabaseReference = FIRDatabase.database().reference().child("registeredUsernames")

    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    // MARK: View
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set background gradient
        self.view.layer.insertSublayer(self.renderGradientLayer(), at: 0)
        
        // Set button rounded edges amd color
        createAccountButton.layer.cornerRadius = Constants.Radius.regularRadius
        createAccountButton.backgroundColor = Constants.Colors.primaryAccent
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: Button Handling
    // ==========================================
    // ==========================================
    @IBAction func didTapCreateAccount(_ sender: Any) {
        
        if (emailTextField.text == "" || usernameTextField.text! == "" || firstNameTextField.text == ""
            || lastNameTextField.text == "" || passwordTextField.text == "") {
            
            // At least one required field is empty
            self.presentSimpleAlert(title: "Missing Fields", message: "Please fill in all required information", completion: nil)
            return
        }
        
        // Make sure all important info is provided, then store
        guard let email = emailTextField.text, let password = passwordTextField.text,
            let firstName = firstNameTextField.text, let lastName = lastNameTextField.text
        else { return }
        
        let username = (self.usernameTextField.text == nil) ? email.components(separatedBy: "@")[0] : self.usernameTextField.text!
        
        
        // ERROR CASE 1: Weak password
        if (password.characters.count < 6) {
            
            presentSimpleAlert(title: "Password is Too Weak", message: "Your password must be 6 or more characters.", completion: {
                self.passwordTextField.becomeFirstResponder()
            })
            
            return
        }
        
        // ERROR CASE 2: Improper username specified at signup
        // TODO: Look into restrictions on <FIRDataSnapshot>.hasChild() which will affect valid usernames
        if (username.characters.count < 4 || username.contains(" ")) {

            presentSimpleAlert(title: "Username is Invalid", message: "Your username must be 4 or more valid characters", completion: {
                self.usernameTextField.becomeFirstResponder()
            })
            
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
                        print("AT.ME:: \(error.localizedDescription)")
                        return
                    }
                    
                    
                    // Add entry to database with public user information (username, email)
                    // All fields are accounted for, displayName defaults to username
                    
                    let userEntry = ["displayName" : username, "email" : email, "firstName" : firstName,
                        "lastName" : lastName, "username" : username]
                    
                    
                    // Add entry to usernames registry and user info registry
                    self.registeredUsernamesRef.child(username).setValue((user?.uid)!)
                    self.userInformationRef.child((user?.uid)!).setValue(userEntry)
                    
                    // Update any <FIRUser> properties maintained internally by Firebase
                    let changeRequest = user?.profileChangeRequest()
                    changeRequest?.displayName = username
                    
                    // First time use, set up user name then log into app
                    print("AT.ME:: New user creation successful")
                    self.setAccountDetails(user!, username, firstName, lastName)
                    self.attemptLogin(withEmail: email, andPassword: password)
                }
                
                
            } else {
                
                // ERROR CASE 3: Username was already taken
                self.presentSimpleAlert(title: "Username Already Taken", message: "Please choose another username.", completion: {
                    self.usernameTextField.becomeFirstResponder()
                })
            }
        })
    }
    
    
    // MARK: Login Processing
    // ==========================================
    // ==========================================
    private func attemptLogin(withEmail email: String, andPassword password: String) {
        
        // Let the auth object sign in the user with given credentials
        FIRAuth.auth()?.signIn(withEmail: email, password: password) { (user, error) in
            
            // In the case of invalid login, handle gracefully
            if let error = error {
                
                // TODO: Handle seemingly impossible case of failed login after account creation
                
                print("AT.ME:: Login failed, however account was created\n\(error.localizedDescription)");
                self.presentSimpleAlert(title: "Invalid Login", message: "Please double check your email and password", completion: nil)
                
                return
            }
            
            // At this point, sign in was successful
            self.processSignIn(forUser: user)
        }
    }
    
    // ==========================================
    // ==========================================
    private func processSignIn(forUser user: FIRUser?) {
        
        // If any of the user details are nil, report error and break
        if let uid = user?.uid, let email = user?.email {
            
            // TODO: Implement error handling in case of failed read for 'username' record
            userInformationRef.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                UserState.currentUser.username = snapshot.childSnapshot(forPath: "\(uid)/username").value as? String
            })
            
            // Maintain information of current user for duration of the app lifetime
            UserState.currentUser.uid = uid
            UserState.currentUser.email = email
            
        } else {
            
            print("AT.ME:: Login unsuccessful due to nil properties for the FIRUser")
            presentSimpleAlert(title: "Something Went Wrong", message: "Please try signing in again.", completion: nil)
            
            return
        }
        
        // Initiate segue to next view
        self.performSegue(withIdentifier: Constants.Segues.signUpSuccessSegue, sender: nil)
        print("AT.ME:: Login successful")
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
            
            if let error = error { print("AT.ME:: \(error.localizedDescription)"); return }
        }
    }
    
    // ==========================================
    // Go back (dismiss) to sign in controller
    // ==========================================
    @IBAction func transitionToSignIn(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
}
