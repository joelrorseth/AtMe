//
//  SignInViewController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-02-18.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase

class SignInViewController: UIViewController, AlertController {
    
    // Firebase references
    private lazy var userInformationRef: DatabaseReference = Database.database().reference().child("userInformation")
    
    let authController = AuthController()
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    
    // MARK: Buttons
    /** Action method that fires when the 'Sign In' button is pressed. */
    @IBAction func didTapSignIn(_ sender: Any) {
        
        if (!fieldsAreFilled()) {
            presentSimpleAlert(title: "Missing Fields", message: Constants.Errors.missingFields, completion: nil)
            return
        }
        
        guard let email = emailField.text, let password = passwordField.text else { return }
        
        authController.signIn(email: email, password: password, completion: { error, configured in
            
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
            self.performSegue(withIdentifier: Constants.Segues.signInSuccessSegue, sender: nil)
        })
    }
    
    
    // MARK: View
    /** Overridden method called after view controller's view is loaded into memory. */
    override func viewDidLoad() {
        super.viewDidLoad()
        addKeyboardObservers()
        
        // Set background gradient
        self.view.layer.insertSublayer(self.renderGradientLayer(), at: 0)
        
        // Set button rounded edges amd color
        signInButton.layer.cornerRadius = Constants.Radius.regularRadius
        signInButton.backgroundColor = Constants.Colors.primaryAccent
    }
    
    
    /** Overridden method called when view controller is soon to be added to view hierarchy. */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let user = Auth.auth().currentUser {
            print("Auth detected a user already signed into the application")
            
            // Ask the Authorization Controller to use previously authorized User object to sign in
            // Will return bool to indicate if this autmatic login could be performed safely
            
            authController.establishCurrentUser(user: user, completion: { configured in
                
                // Successful configuration allows segue to next view without having to type anything!
                if (configured) {
                    self.performSegue(withIdentifier: Constants.Segues.signInSuccessSegue, sender: nil)
                    
                } else {
                    
                    print("Error: Could not obtain information from database about previously authorized user")
                    self.presentSimpleAlert(title: "Automatic Login Error", message: Constants.Errors.unestablishedCurrentUser, completion: nil)
                }
            })
        }
    }
    
    
    /** Overridden variable which will determine the style of this view controller's status bar (eg. dark or light). */
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    // MARK: Keyboard Handling
    /** Add gesture recognizer to the view to allow keyboard dismiss */
    private func addKeyboardObservers() {
        
        // Add gesture recognizer to handle tapping outside of keyboard
        let dismissKeyboardTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(dismissKeyboardTap)
    }
    
    
    /** Dismiss the keyboard from screen if currently displayed. */
    func dismissKeyboard() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }
    
    
    // MARK: Validation
    /** Determine if all text fields in the view controller are filled in. */
    private func fieldsAreFilled() -> Bool {
        return emailField.text != "" && passwordField.text != ""
    }
    
    
    // MARK: Segue
    /** Method stub for unwind segue to this view controller from another. */
    @IBAction func unwindToSignIn(segue: UIStoryboardSegue) {}
}
