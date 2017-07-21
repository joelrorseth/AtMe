//
//  SignUpViewController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-03-10.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController, AlertController {
    

    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    private var email: String = ""
    private var firstName: String = ""
    private var lastName: String = ""
    private var password: String = ""
        
    
    // MARK: View
    /** Overridden method called after view controller's view is loaded into memory. */
    override func viewDidLoad() {
        super.viewDidLoad()
        addKeyboardObservers()
        
        // Set background gradient
        self.view.layer.insertSublayer(self.renderGradientLayer(), at: 0)
        
        self.navigationController?.isNavigationBarHidden = true
        
        // Set button rounded edges amd color
        createAccountButton.layer.cornerRadius = Constants.Radius.regularRadius
        createAccountButton.backgroundColor = Constants.Colors.primaryAccent
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
        view.addGestureRecognizer(dismissKeyboardTap)
    }
    
    
    /** Dismiss the keyboard */
    func dismissKeyboard() {
        firstNameTextField.resignFirstResponder()
        lastNameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    
    // MARK: Button Handling
    /** Go back (dismiss) to sign in controller */
    @IBAction func transitionToSignIn(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    
    /** Action method which fires when the user presses the 'Create Account' button. */
    @IBAction func didTapCreateAccount(_ sender: Any) {
        
        if (!fieldsAreFilled()) {
            self.presentSimpleAlert(title: "Missing Fields", message: "Please fill in all required information", completion: nil)
            return
        }
        
        
        // If fields are adequate, set properties that will be passed to next screen
        if (profileSettingsAreAdequate()) {
            
            email = emailTextField.text!
            firstName = firstNameTextField.text!
            lastName = lastNameTextField.text!
            password = passwordTextField.text!
            
            self.performSegue(withIdentifier: Constants.Segues.signUpSuccessSegue, sender: nil)
        }
    }
    
    
    // MARK: Validation
    /** Determine if all text fields in the view controller are filled in. */
    private func fieldsAreFilled() -> Bool {
        
        return emailTextField.text != "" && firstNameTextField.text != ""
            && lastNameTextField.text != "" && passwordTextField.text != ""
    }
    
    
    /** Determine if the values entered by user are adequate to use when creating a user. */
    private func profileSettingsAreAdequate() -> Bool {
        
        // Prevent any further checking until we know all fields are non-nil
        // This should have been taken care of in fieldsAreFilled()
        
        guard let firstName = firstNameTextField.text, let lastName = lastNameTextField.text,
            let password = passwordTextField.text else { return false }
        
        // Iterate through each field to check for rules applying to all fields
        for field in [firstName, lastName, password] {
            
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
                               completion: { _ in self.passwordTextField.becomeFirstResponder() })
            return false
        }
        
        return true
    }
    
    
    // MARK: Segue
    /** Overridden method providing an opportunity for data transfer to destination view controller before segueing to it. */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let userSetupVC = segue.destination as! UserSetupViewController
        
        // Pass along form information from this controller to the next
        // We want to avoid signing in or creating an account until ALL fields are obtained...
        
        userSetupVC.email = self.email
        userSetupVC.firstName = self.firstName
        userSetupVC.lastName = self.lastName
        userSetupVC.password = self.password
    }
}
