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
  
  lazy var databaseManager = DatabaseController()
  var authManager: AuthManager = FirebaseAuthManager()
  
  @IBOutlet var usernameTextField: UITextField!
  @IBOutlet var displayPictureImageView: UIImageView!
  @IBOutlet var createAccountButton: UIButton!
  
  // These should be set upon segue by SignUpViewController
  var email: String = ""
  var firstName: String = ""
  var lastName: String = ""
  var password: String = ""
  var selectedDisplayPictureData: Data? = nil
  
  
  /** Action method which fires when the user taps the 'Back' button. */
  @IBAction func didTapBackButton(_ sender: Any) {
    navigationController?.popViewController(animated: true)
  }
  
  
  // TODO: This is kinda a nightmare. Should refactor to try and avoid callback hell
  // However, Firebase doesn't really provide 'completion' callbacks with their own functions :(
  // Signup was a bit slow, particularily after account creation, but this is small inconvenience
  
  /** Action method which fires when the user presses the finish button. */
  @IBAction func didPressFinish(_ sender: Any) {
    
    if (validateInput()) {
      guard let username = usernameTextField.text else { return }
      
      
      
      // Let the Auth Controller attempt to create the account
      authManager.createAccount(email: self.email, firstName: self.firstName, lastName: self.lastName, password: self.password, completion: { (error, uid) in
        
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
            self.authManager.setDisplayPicture(path: path)
          })
        }
        
        
        // If the username does not exist, proceed with account creation
        self.authManager.usernameExists(username: username, completion: { exists in
          if (!exists) {
            
            // Once username is set, sign in for the first time
            self.authManager.setUsername(username: username, completion: {
              self.authManager.signIn(email: self.email, password: self.password, completion: { (error, configured) in
                
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
  /** Overridden method called after view controller's view is loaded into memory. */
  override func viewDidLoad() {
    super.viewDidLoad()
    addKeyboardObservers()
    
    setupView()
    
    // Add gesture recognizer to the profile picture UIImageView
    let imageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UserSetupViewController.promptImageSelection))
    
    displayPictureImageView.addGestureRecognizer(imageGestureRecognizer)
    displayPictureImageView.isUserInteractionEnabled = true
  }
  
  
  /** Set up the look and feel of this view controller and related views. */
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
  
  
  /** Overridden variable which will determine the style of this view controller's status bar (eg. dark or light). */
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  
  // MARK: Keyboard Handling
  /** Add gesture recognizer to the view to allow keyboard dismiss. */
  private func addKeyboardObservers() {
    
    // Add gesture recognizer to handle tapping outside of keyboard
    let dismissKeyboardTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    view.addGestureRecognizer(dismissKeyboardTap)
  }
  
  
  /** Dismiss the keyboard from screen if currently displayed. */
  @objc func dismissKeyboard() {
    usernameTextField.resignFirstResponder()
  }
  
  
  /** Determines if the input entered in the view controller is valid, and can be used to create account.
   - returns: True if input is valid, false otherwise
   */
  private func validateInput() -> Bool {
    
    if let username = usernameTextField.text {
      if (username.count < 4) {
        
        presentSimpleAlert(title: "Username is Invalid", message: Constants.Errors.usernameLength,
                           completion: { _ in self.usernameTextField.becomeFirstResponder() })
        return false
      }
      
      if (username.contains(".") || username.contains("$") || username.contains("#") ||
        username.contains("[") || username.contains("]") || username.contains("/") ||
        username.contains(" ") || username.contains(" ") || username == "" ||
        username.count < 3 ) {
        
        presentSimpleAlert(title: "Invalid Characters", message: Constants.Errors.invalidCharacters, completion: nil)
        return false
      }
      
      return true
      
    } else { return false }
  }
  
  
  // TODO: In future update, this can maybe be refactored into custom UIImageView
  /** Selector method which triggers a prompt for a UIImagePickerController. */
  @objc func promptImageSelection() {
    
    // Create picker, and set this controller as delegate
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.allowsEditing = true
    
    // Call AlertController method to display ActionSheet allowing Camera or Photo Library selection
    // Use callback to set picker source type determined in the alert controller
    
    presentPhotoSelectionPrompt(completion: { (sourceType: UIImagePickerControllerSourceType?) in
      
      if let sourceType = sourceType {
        picker.sourceType = sourceType
        self.present(picker, animated: true, completion: nil)
      }
    })
  }
}


// MARK: Image Picker Delegate Methods
extension UserSetupViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  // TODO: In future update, refactor
  /** Called when media has been selected by the user in the image picker. */
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    
    // Dismiss immediately to appear responsive
    dismiss(animated: true)
    
    // Extract the image after editing, upload to database as Data object
    if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
      if let data = convertImageToData(image: image) {
        
        // Store in property until the Finish button is pressed, throw it into imageView temporarily
        // It will then be used to be uploaded to servers and set as user display picture
        selectedDisplayPictureData = data
        displayPictureImageView.image = image
        
      } else { print("AtMe:: Error extracting image from camera source") }
    } else { print("AtMe:: Error extracting edited UIImage from info dictionary") }
  }
  
  
  /** Called if and when the user has cancelled the image picking operation. */
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true)
  }
}
