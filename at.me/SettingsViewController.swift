//
//  SettingsViewController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-03-01.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Photos
import Firebase

class SettingsViewController: UITableViewController, AlertController {
    
    lazy var userInformationRef: FIRDatabaseReference = FIRDatabase.database().reference().child("userInformation")
    lazy var userDisplayPictureRef: FIRStorageReference = FIRStorage.storage().reference().child("displayPictures")
    
    var currentAttributeChanging: Constants.UserAttribute = Constants.UserAttribute.none
    var attributePrompt: String = ""

    @IBOutlet weak var userPictureImageView: UIImageView!
    @IBOutlet weak var userDisplayNameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    
    
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Add gesture recognizer to the profile picture UIImageView
        let imageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SettingsViewController.promptImageSelection))
        
        userPictureImageView.addGestureRecognizer(imageGestureRecognizer)
        userPictureImageView.isUserInteractionEnabled = true
        
        loadCurrentUserInformation()
    }
    
    // ==========================================
    // ==========================================
    private func loadCurrentUserInformation() {
        
        // Should never happen, app blocks until these have been set at login
        userDisplayNameLabel.text = UserState.currentUser.displayName ?? "Loading..."
        usernameLabel.text = UserState.currentUser.username ?? "Loading..."
        
        // Display picture may very well be nil if not set or loaded yet
        // This is because display pictures are loaded asynchronously at launch
        
        if let image = UserState.currentUser.displayPicture {
            userPictureImageView.image = image
        }
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
    
    // ==========================================
    // ==========================================
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    // ==========================================
    // ==========================================
    func dismissPopup() {
        self.view.endEditing(true)

        // Animate the popup off screen (downwards), fade view back in from dimmed state
        UIView.animate(withDuration: 0.9, animations: {
            
            self.view.viewWithTag(1000)?.frame.origin.y = 3000
            self.view.viewWithTag(2000)?.alpha = 0.0
            
        }, completion: { completion in
            
            // Remove popup view and dimmed view once completed animation
            self.view.viewWithTag(1000)?.removeFromSuperview()
            self.view.viewWithTag(2000)?.removeFromSuperview()
        })
    }
    
    // ==========================================
    // ==========================================
    func updateUserAttribute(forKey: String, value: String) {
        
    }
    
    // ==========================================
    // ==========================================
//    func changeSaved() {
//        
//        // Find text field with changed attribute, unwrap
//        if let textfield = self.view.viewWithTag(4000) as? UITextField {
//            
//            // Check if attribute is suitable
//            if let newAttribute = textfield.text {
//                
//                
//                // SPECIAL CASE 1: Password change
//                // ---------------------------------------------
//                if currentAttributeChanging == .password {
//                    
//                    FIRAuth.auth()?.sendPasswordReset(withEmail: (FIRAuth.auth()?.currentUser?.email!)!, completion: { (error) in
//                        
//                        // Alert user of password reset, dismiss popup
//                        self.presentSimpleAlert(
//                            title: "Your Password Has Been Reset",
//                            message: "Please check your emails for instructions on how to change your password",
//                            completion: { self.dismissPopup() })
//                    })
//                }
//                
//                
//                // TODO: SPECIAL CASE 2: Email change (May not be possible due to Firebase restrictions)
//                // ---------------------------------------------
//                if currentAttributeChanging == .email {
//                    
//                    //let changeRequest = FIRAuth.auth()?.currentUser?.profileChangeRequest()
//                }
//                
//                
//                
//                // SPECIAL CASE 3: Display Name
//                // ---------------------------------------------
//                if currentAttributeChanging == .displayName {
//                    
//                    // Change Firebase's internal record of <FIRUser>.displayName
//                    let changeRequest = FIRAuth.auth()?.currentUser?.profileChangeRequest()
//                    changeRequest?.displayName = newAttribute
//                    UserState.currentUser.displayName = newAttribute
//                    
//                    // Allow fallthrough to allow our maintained user records to be updated
//                }
//                
//             
//                // All Other Changes
//                // Lookup and change user attribute
//                // ---------------------------------------------
//                if let user = FIRAuth.auth()?.currentUser {
//                    
//                    userInformationRef.child(String(user.uid)).child("\(currentAttributeChanging)").setValue(newAttribute)
//                    self.dismissPopup()
//                }
//            }
//        }
//        
//        loadCurrentUserInformation()
//        self.tableView.reloadData()
//    }
    
    // ==========================================
    // ==========================================
    func logout() {
        
        // Present a confirmation dialog to logout
        let ac = UIAlertController(title: "Confirm Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        ac.addAction(UIAlertAction(title: "Logout", style: .default, handler: { (action) in
            
            do {
                // Attempt to logout, may throw error
                try FIRAuth.auth()?.signOut()
                
                // At this point, signOut() succeeded by not throwing any errors
                self.performSegue(withIdentifier: "unwindToSignIn", sender: self)
                print("AT.ME:: Successfully logged out")
                
            } catch let error as NSError {
                print("AT.ME:: \(error.localizedDescription)")
            }
        }))
        
        // Present the alert
        self.present(ac, animated: true, completion: nil)
    }
    
    // ==========================================
    // ==========================================
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "ShowPrompt" {
            if let destination = segue.destination as? PromptViewController {
                let selectedRow = tableView.indexPathForSelectedRow!.row
                
                destination.changingAttribute = Constants.UserAttribute(rawValue: selectedRow + 1)!
            }
        }
    }
}


// MARK: Image Picker Delegate Methods
extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // ==========================================
    // ==========================================
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // TODO: Refactor
        // TODO: Save edited image
        // TODO: Cache image
        
        guard let uid = UserState.currentUser.uid else { return }
        
        // Full destination path in Firebase (with file extension)
        let path = "\(uid)/\(uid).JPG"
        
        
        // Case 1: Image was selected from photo library
        if let imageURL = info[UIImagePickerControllerReferenceURL] as? String {
            
            let url = URL(fileURLWithPath: imageURL)
            
            // Use PHAsset class to manage stored images in device Photo Library
            let assets = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil)
            let asset = assets.firstObject
            
            asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
                
                let file = contentEditingInput?.fullSizeImageURL    // URL for photo on device
    
                // Use putFile() to upload photo from device using its local URL
                self.userDisplayPictureRef.child(path).putFile(file!, metadata: nil) { (metadata, error) in
                    
                    if let error = error {
                        print("AT.ME:: Error uploading display picture to Firebase \(error.localizedDescription)")
                        return
                    }
                    
                    // Record Storage URL in user information record
                    // This is important, allows display image to be cached at app launch
                    
                    self.userInformationRef.child("\(uid)/displayPicture").setValue(path)
                }
                
            })
            
        }
        
        // Case 2: Image was taken by camera
        else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            // Convert UIImage -> Data for storage purposes
            let imageData = UIImageJPEGRepresentation(image, 1.0)
            
            // Use put() to upload photo using a Data object
            userDisplayPictureRef.child(path).put(imageData!, metadata: nil) { (metadata, error) in
                
                if let error = error {
                    print("AT.ME:: Error uploading display picture to Firebase \(error.localizedDescription)")
                    return
                }
                
                self.userInformationRef.child("\(uid)/displayPicture").setValue(path)
            }
        }
        
        else {
            
            print("AT.ME:: Error extracting selected photo from UIImagePickerController")
            return
        }
        
        dismiss(animated: true)
    }
    
    // ==========================================
    // ==========================================
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}



// MARK: Table View
extension SettingsViewController {
    
    // ==========================================
    // ==========================================
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
//        if (indexPath.section == 1) {
//            let changingAttribute: Constants.UserAttribute
//            
//            switch (indexPath.row) {
//            case 0:
//                changingAttribute = .displayName
//                break
//            case 1:
//                changingAttribute = .firstName
//                break
//            case 2:
//                changingAttribute = .lastName
//                break
//            default:
//                return
//            }
        
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "ShowPrompt", sender: self)
            }
        
    
        
//        // Determine which attributes have been chosen for edit
//        switch indexPath.row {
//        case 1:
//            currentAttributeChanging = .displayName
//            attributePrompt = "display name"
//            break
//        case 2:
//            currentAttributeChanging = .email
//            attributePrompt = "email address"
//            break
//        case 3:
//            currentAttributeChanging = .firstName
//            attributePrompt = "first name"
//            break
//        case 4:
//            currentAttributeChanging = .lastName
//            attributePrompt = "last name"
//            break
//        case 5:
//            currentAttributeChanging = .password
//            attributePrompt = "password"
//            break
//        case 6:
//            self.logout()
//            return
//        default:
//            break
//        }
//        
//        // TODO: Refactor custom view code (possibly into separate file)
//        // Dimmed view appears on top of self.view, but under popup view
//        let dimmedView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
//        dimmedView.backgroundColor = UIColor.black
//        dimmedView.alpha = 0.0
//        dimmedView.tag = 2000
//        
//        // Custom view to contain the popup
//        let popupView = UIView(frame: CGRect(x: 10, y: 3000, width: view.bounds.size.width - 20, height: 250))
//        popupView.layer.cornerRadius = 5
//        popupView.layer.opacity = 0.98
//        popupView.alpha = 0.0
//        popupView.backgroundColor = UIColor.white
//        popupView.tag = 1000
//        
//        // Label is added to the popup view
//        let label = UILabel(frame: CGRect(x: 0, y: 20, width: popupView.bounds.size.width, height: 20))
//        label.textColor = UIColor.black
//        label.textAlignment = .center
//        label.font = UIFont(name: "System", size: 14)
//        label.text = "Enter a new \(attributePrompt)"
//        
//        // Text field is added to the popup view
//        let textField = UITextField(frame: CGRect(x: 20, y: 50, width: popupView.bounds.size.width - 40, height: 34))
//        textField.tag = 4000
//        textField.borderStyle = .roundedRect
//        textField.textColor = UIColor.darkGray
//        textField.textColor = UIColor.black
//        
//        // Button is added to the popup view
//        let button = UIButton(frame: CGRect(x: 30, y: popupView.bounds.size.height - 70, width: popupView.bounds.size.width - 60, height: 50))
//        button.addTarget(self, action: #selector(changeSaved), for: UIControlEvents.touchUpInside)
//        button.backgroundColor = UIColor.darkGray
//        button.contentHorizontalAlignment = .center
//        button.setTitle("Save Changes", for: .normal)
//        button.setTitleColor(UIColor.white, for: .normal)
//        button.titleLabel?.font = UIFont(name: "System", size: 16)
//        button.layer.cornerRadius = 5
//        
//        popupView.addSubview(label)
//        popupView.addSubview(textField)
//        popupView.addSubview(button)
//        
//        // Add gesture recognizer to handle tapping outside of keyboard
//        dimmedView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissPopup)))
//        popupView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
//        
//        self.view.addSubview(dimmedView)
//        self.view.addSubview(popupView)
//        
//        // Animate the custom popup in and dim the background
//        UIView.animate(withDuration: 0.5, animations: {
//            dimmedView.layer.opacity = 0.7
//            popupView.alpha = 1.0
//            popupView.frame.origin.y = 50
//        })
//    }
    }
}
