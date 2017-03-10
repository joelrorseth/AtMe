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
    //private lazy var registeredUsernamesRef: FIRDatabaseReference = FIRDatabase.database().reference().child("registeredUsernames")
    
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
            self.performSegue(withIdentifier: Constants.Segues.signInSuccessSegue, sender: nil)
        }
    }
    
    
    // MARK: View
    // ==========================================
    // ==========================================
    override func viewDidAppear(_ animated: Bool) {
        
        if let currentUser = FIRAuth.auth()?.currentUser {
            print("<<<< AT.ME::DEBUG >>>>: Automatically logged in \((currentUser.email)!)")
            self.performSegue(withIdentifier: Constants.Segues.signInSuccessSegue, sender: nil)
        }
    }
    
    // MARK: Segue
    // ==========================================
    // ==========================================
    @IBAction func unwindToSignIn(segue: UIStoryboardSegue) {}
}
