//
//  SignInViewController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-02-18.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase

class SignInViewController: UIViewController, AlertController {
    
    // Firebase references
    private lazy var userInformationRef: DatabaseReference = Database.database().reference().child("userInformation")
    private lazy var userDisplayPictureRef: StorageReference = Storage.storage().reference().child("displayPictures")
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    let authController = AuthController()
    
    
    // MARK: Buttons
    // ==========================================
    // ==========================================
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
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set background gradient
        self.view.layer.insertSublayer(self.renderGradientLayer(), at: 0)
        
        // Set button rounded edges amd color
        signInButton.layer.cornerRadius = Constants.Radius.regularRadius
        signInButton.backgroundColor = Constants.Colors.primaryAccent
    }
    
    // ==========================================
    // ==========================================
    override func viewDidAppear(_ animated: Bool) {
        
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
    
    // ==========================================
    // ==========================================
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    // MARK: Validation
    // ==========================================
    // ==========================================
    private func fieldsAreFilled() -> Bool {
        return emailField.text != "" && passwordField.text != ""
    }
    
    // MARK: Segue
    // ==========================================
    // ==========================================
    @IBAction func unwindToSignIn(segue: UIStoryboardSegue) {}
}
