//
//  UserSetupViewController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-06-25.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase

class UserSetupViewController: UIViewController, AlertController {
    
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var displayPictureImageView: UIImageView!
    @IBOutlet var createAccountButton: UIButton!
    
    // These should be set upon segue by SignUpViewController
    var email: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var password: String = ""
    var selectedDisplayPictureData: Data? = nil
    
    // FIXME: Pass around one AuthController if possible between SignIn and SignUp
    internal let authController = AuthController()
    internal let databaseManager = DatabaseController()

    // ==========================================
    // ==========================================
    @IBAction func didTapBackButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // TODO: This is kinda a nightmare. Should refactor to try and avoid callback hell
    // However, Firebase doesn't really provide 'completion' callbacks with their own functions :(
    // Signup was a bit slow, particularily after account creation
    
    // ==========================================
    // ==========================================
    @IBAction func didPressFinish(_ sender: Any) {
        
        if (validateInput()) {
            guard let username = usernameTextField.text else { return }
            
            
            
            // Let the Auth Controller attempt to create the account
            self.authController.createAccount(email: self.email, firstName: self.firstName, lastName: self.lastName, password: self.password, completion: { (error, uid) in
                
                if let error = error {
                    self.presentSimpleAlert(title: "Authorization Error", message: error.localizedDescription, completion: nil)
                    return
                }
                
                
                // First time use, set up user name then log into app
                print("AtMe:: Successfully created new user ")
                
                // If picture was selected, upload it now that account has been created and UID retrieved
                if let data = self.selectedDisplayPictureData, let uid = uid {
                    
                    // Let the Database Controller take care of upoading using this general display picture URL
                    let path = "displayPictures/\(uid)/\(uid).JPG"
                    self.databaseManager.uploadImage(data: data, to: path, completion: { error in
                        if let error = error {
                            print("AtMe:: Error uploading display picture to Firebase. \(error.localizedDescription)")
                            return
                        }
                        
                        // Important: Auth Controller will associate the picture with the user profile
                        self.authController.setDisplayPicture(path: path)
                    })
                }
                
                
                // If the username does not exist, proceed with account creation
                self.authController.usernameExists(username: username, completion: { exists in
                    if (!exists) {
                        
                        // Once username is set, sign in for the first time
                        self.authController.setUsername(username: username, completion: {
                            self.authController.signIn(email: self.email, password: self.password, completion: { (error, configured) in
                                
                                if let error = error {
                                    self.presentSimpleAlert(title: "Could Not Sign In", message: error.localizedDescription, completion: nil)
                                    return
                                } else if (!configured) {
                                    self.presentSimpleAlert(title: "Sign In Error Occured", message: Constants.Errors.signInBadConfig, completion: nil)
                                    return
                                }
                                
                                // If error was not set, sign in was successful
                                // Initiate segue to next view controller
                                self.performSegue(withIdentifier: Constants.Segues.createAccountSuccessSegue, sender: nil)
                            })
                        })
                    }
                })
            })
        }
    }
    
    // MARK: View
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        addKeyboardObservers()
        
        setupView()
        
        // Add gesture recognizer to the profile picture UIImageView
        let imageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UserSetupViewController.promptImageSelection))
        
        displayPictureImageView.addGestureRecognizer(imageGestureRecognizer)
        displayPictureImageView.isUserInteractionEnabled = true
    }
    
    // ==========================================
    // ==========================================
    private func setupView() {
        
        // Set background gradient
        self.view.layer.insertSublayer(self.renderGradientLayer(), at: 0)
        
        // Set button rounded edges amd color
        createAccountButton.layer.cornerRadius = Constants.Radius.regularRadius
        createAccountButton.backgroundColor = Constants.Colors.primaryAccent
        
        displayPictureImageView.layer.masksToBounds = true
        displayPictureImageView.layer.cornerRadius = displayPictureImageView.frame.width / 2
        displayPictureImageView.layer.borderColor = UIColor.white.cgColor
        displayPictureImageView.layer.borderWidth = 1.3
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
        usernameTextField.resignFirstResponder()
    }
    
    // ==========================================
    // ==========================================
    private func validateInput() -> Bool {
        
        if let username = usernameTextField.text {
            if (username.characters.count < 4) {
                
                presentSimpleAlert(title: "Username is Invalid", message: Constants.Errors.usernameLength,
                                   completion: { _ in self.usernameTextField.becomeFirstResponder() })
                return false
            }
            
            if (username.contains(".") || username.contains("$") || username.contains("#") ||
                username.contains("[") || username.contains("]") || username.contains("/") ||
                username.contains(" ") || username.contains(" ") || username == "" ||
                username.characters.count < 3 ) {
                
                presentSimpleAlert(title: "Invalid Characters", message: Constants.Errors.invalidCharacters, completion: nil)
                return false
            }
            
            return true
        
        } else { return false }
    }
    
    
    // ==========================================
    // ==========================================
    func promptImageSelection() {
        
        // Create picker, and set this controller as delegate
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        // Call AlertController method to display ActionSheet allowing Camera or Photo Library selection
        // Use callback to set picker source type determined in the alert controller
        
        presentPhotoSelectionPrompt(completion: { (sourceType: UIImagePickerControllerSourceType) in
            
            picker.sourceType = sourceType
            self.present(picker, animated: true, completion: nil)
        })
    }
}


// MARK: Image Picker Delegate Methods
extension UserSetupViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // TODO: Refactor this method and near identical copy in SettingsViewController into one
    // ==========================================
    // ==========================================
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // Extract the image after editing, upload to database as Data object
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            if let data = convertImageToData(image: image) {
                
                // Store in property until the Finish button is pressed, throw it into imageView temporarily
                // It will then be used to be uploaded to servers and set as user display picture
                selectedDisplayPictureData = data
                displayPictureImageView.image = image
                
            } else { print("AtMe:: Error extracting image from camera source") }
        } else { print("AtMe:: Error extracting edited UIImage from info dictionary") }
        
        dismiss(animated: true)

    }

    // ==========================================
    // ==========================================
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}
