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
                
                print("AT.ME:: Login unsuccessful")
                return
            }
            
            self.processSignIn(forUser: user)
        }
    }
    
    
    // MARK: View
    // ==========================================
    // ==========================================
    override func viewDidAppear(_ animated: Bool) {
        
        if let currentUser = FIRAuth.auth()?.currentUser {
            self.processSignIn(forUser: currentUser)
        }
    }
    
    // MARK: Segue
    // ==========================================
    // ==========================================
    @IBAction func unwindToSignIn(segue: UIStoryboardSegue) {}
    
    
    // MARK: Additional Functions
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
            
            // Let user know that email/password is invalid
            let ac = UIAlertController(title: "Something Went Wrong", message: "Please try signing in again.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(ac, animated: true, completion: nil)
            
            print("AT.ME:: Login unsuccessful due to nil properties for the FIRUser")
            return
        }
        
        // Initiate segue to next view
        self.performSegue(withIdentifier: Constants.Segues.signInSuccessSegue, sender: nil)
        print("AT.ME:: Login successful")
    }
}
