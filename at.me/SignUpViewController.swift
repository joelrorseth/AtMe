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
    

    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // FIXME: Pass around one AuthController if possible between SignIn and SignUp
    let authController = AuthController()
        
    
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
    
    // ==========================================
    // ==========================================
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    // MARK: Button Handling
    // ==========================================
    // Go back (dismiss) to sign in controller
    // ==========================================
    @IBAction func transitionToSignIn(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    
    // ==========================================
    // ==========================================
    @IBAction func didTapCreateAccount(_ sender: Any) {
        
        if (!fieldsAreFilled()) {
            self.presentSimpleAlert(title: "Missing Fields", message: "Please fill in all required information", completion: nil)
            return
        }
        

        // Proceed with account creation only if profile settings are ok, and
        // all fields can be explicitly unwrapped
        
        guard let email = emailTextField.text, let username = usernameTextField.text,
            let firstName = firstNameTextField.text, let lastName = lastNameTextField.text,
            let password = passwordTextField.text else { return }
        
        // If fields are adequate, and this @Me username is not taken, proceed with account creation
        if (profileSettingsAreAdequate()) {
            
            // Let the Auth Controller attempt to create the account
            authController.createAccount(email: email, username: username, firstName: firstName,
                lastName: lastName, password: password, completion: { (error, taken) in
                                       
                    if let error = error {
                        self.presentSimpleAlert(title: "Authorization Error", message: error.localizedDescription, completion: nil)
                        return
                    
                    } else if (taken) {
                        self.presentSimpleAlert(title: "Username taken", message: Constants.Errors.usernameTaken, completion: nil)
                        return
                    }
                    
                    // First time use, set up user name then log into app
                    print("AT.ME:: Successfully created new user ")
                    
                    self.authController.signIn(email: email, password: password, completion: { (error, configured) in
    
                        if let error = error {
                            self.presentSimpleAlert(title: "Could Not Sign In", message: error.localizedDescription, completion: nil)
                            return
                        }
                        
                        if (!configured) {
                            self.presentSimpleAlert(title: "Sign In Error Occured", message: Constants.Errors.signInBadConfig, completion: nil)
                            return
                        }
                        
                        // If error was not set, sign in was successful
                        // Initiate segue to next view controller
                        self.performSegue(withIdentifier: Constants.Segues.signUpSuccessSegue, sender: nil)
                    })
            })
        }
    }
    
    
    // MARK: Validation
    // ==========================================
    // ==========================================
    private func fieldsAreFilled() -> Bool {
        
        return emailTextField.text != "" && usernameTextField.text! != "" && firstNameTextField.text != ""
            && lastNameTextField.text != "" && passwordTextField.text != ""
    }
    
    // ==========================================
    // ==========================================
    private func profileSettingsAreAdequate() -> Bool {
        
        // Prevent any further checking until we know all fields are non-nil
        // This should have been taken care of in fieldsAreFilled()
        
        guard let username = usernameTextField.text, let firstName = firstNameTextField.text,
            let lastName = lastNameTextField.text, let password = passwordTextField.text
            else { return false }
        
        // Iterate through each field to check for rules applying to all fields
        for field in [username, firstName, lastName, password] {
            
            // Return false and present alert if illegal characters are found
            if (field.contains(".") || field.contains("$") || field.contains("#") ||
                field.contains("[") || field.contains("]") || field.contains("/") || field.contains(" ")) {
                
                presentSimpleAlert(title: "Invalid Characters", message: Constants.Errors.invalidCharacters, completion: nil)
                return false
            }
        }
        
        // Return false and present alert if password is not long enough
        if (password.characters.count < 6) {
            presentSimpleAlert(title: "Password is Too Weak", message: Constants.Errors.passwordLength,
                               completion: { self.passwordTextField.becomeFirstResponder() })
            return false
        }
        
        // Return false and present alert if password is not long enough
        if (username.characters.count < 4 || username.contains(" ")) {
            presentSimpleAlert(title: "Username is Invalid", message: Constants.Errors.usernameLength,
                               completion: { self.usernameTextField.becomeFirstResponder() })
            return false
        }
        
        return true
    }
}
