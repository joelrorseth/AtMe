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
    private lazy var userInformationRef: FIRDatabaseReference = FIRDatabase.database().reference().child("userInformation")
    private lazy var userDisplayPictureRef: FIRStorageReference = FIRStorage.storage().reference().child("displayPictures")
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
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
                print("AT.ME:: Error during login\n\(error.localizedDescription)")
                
                self.presentSimpleAlert(title: "Invalid Login", message: "Please double check your email and password.", completion: nil)
                return
            }
            
            self.processSignIn(forUser: user)
        }
    }
    
    // MARK: View
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set background gradient
        self.view.layer.insertSublayer(self.renderGradientLayer(), at: 0)
        
        // Set button rounded edges amd color
        signInButton.layer.cornerRadius = 12
        signInButton.backgroundColor = Constants.Colors.primaryAccent
    }
    
    // ==========================================
    // ==========================================
    override func viewDidAppear(_ animated: Bool) {
        
        if let currentUser = FIRAuth.auth()?.currentUser {
            self.processSignIn(forUser: currentUser)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
                UserState.currentUser.displayName = snapshot.childSnapshot(forPath: "\(uid)/displayName").value as? String
                
                // Maintain information of current user for duration of the app lifetime
                UserState.currentUser.uid = uid
                UserState.currentUser.email = email
                
                // Note: This block is error safe, handles all errors
                // TODO: Determine if displayPicture recorded path is even necessary since it is predictable using 'uid'
                
                // Load profile picture on a background thread
                // Extract stored path, download data at location if path is set
                
                if let relativeURL = snapshot.childSnapshot(forPath: "\(uid)/displayPicture").value as? String {
                    
                    // Asynchronously download the file data stored at 'path' (display picture)
                    self.userDisplayPictureRef.child(relativeURL).data(withMaxSize: INT64_MAX, completion: { (data, error) in
                        
                        if let image = data {
                            UserState.currentUser.displayPicture = UIImage(data: image)
                            print("AT.ME:: Loaded display picture into local memory")
                        } else {
                            print("AT.ME:: Image data was nil at path: \(relativeURL)")
                        }
                    })
                    
                } else { print("AT.ME:: Did not find a display picture to load") }

                
                
                // Initiate segue to next view
                self.performSegue(withIdentifier: Constants.Segues.signInSuccessSegue, sender: nil)
                print("AT.ME:: Current user set. Login successful")
            })
            
        } else {
            
            presentSimpleAlert(title: "Something Went Wrong", message: "Please try signing in again.", completion: nil)
            print("AT.ME:: Login unsuccessful due to nil properties for the FIRUser")
        }
    }
}
