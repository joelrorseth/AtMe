//
//  SettingsViewController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-03-01.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase

class SettingsViewController: UITableViewController, AlertController {
    
    var currentAttributeChanging: Constants.UserAttribute = Constants.UserAttribute.none
    var attributePrompt: String = ""

    @IBOutlet weak var userPictureImageView: UIImageView!
    @IBOutlet weak var userDisplayNameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var logoutCell: UITableViewCell!
    
    
    /** Overridden method called after view controller's view is loaded into memory. */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add gesture recognizer to the profile picture UIImageView
        let imageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SettingsViewController.promptImageSelection))
        
        userPictureImageView.addGestureRecognizer(imageGestureRecognizer)
        userPictureImageView.isUserInteractionEnabled = true
    }
    
    
    /** Overridden method called when view controller is soon to be added to view hierarchy. */
    override func viewWillAppear(_ animated: Bool) {
        loadCurrentUserInformation()
        
        logoutCell.backgroundColor = Constants.Colors.primaryDark
        userPictureImageView.layer.masksToBounds = true
        userPictureImageView.clipsToBounds = true
        userPictureImageView.layer.cornerRadius = userPictureImageView.frame.size.width / 2
    }
    
    
    /** Updates the UserState and database stored record of the current user's display picture (url). */
    func updateUserDisplayPicture() {
        
        let uid = UserState.currentUser.uid
        let url = "displayPictures/\(uid)/\(uid).JPG"
        
        // Redownload into image into image view
        // Although user may not even have profile picture yet, this method is safe and will clear if cached
        DatabaseController.reloadImage(into: userPictureImageView, from: url, completion: { error in
            if let error = error { print("Error: \(error.localizedDescription)") }
            else { print("Good") }
        })
        
        
        // TODO: Refactor to remove assumption that path in userInfo signifies a valid profile picture
        // Really we can just query database for this directly and let it fail if not found
        AuthController.setDisplayPicture(path: "\(uid)/\(uid).JPG")
        
        // Update current user stored display picture, reload image view
        // loadCurrentUserInformation()
    }
    
    
    // TODO: Eventually show the actual current information greyed out in the table cells
    /** Loads information about the current user into the view. */
    private func loadCurrentUserInformation() {
        
        // Should never happen, app blocks until these have been set at login
        userDisplayNameLabel.text = UserState.currentUser.name
        usernameLabel.text = "@" + UserState.currentUser.username
        
        // UserState is assumed to hold only the relative path of display picture
        // TODO: Change this in the future to full path, or better yet just eliminate it
        guard let picture = UserState.currentUser.displayPicture else {
            presentSimpleAlert(title: "Could Not Set Picture", message: Constants.Errors.displayPictureMissing, completion: nil)
            return
        }
        
        // Display picture may very well be nil if not set or loaded yet
        // This is because display pictures are loaded asynchronously at launch
        
        DatabaseController.downloadImage(into: userPictureImageView,
            from: "displayPictures/\(picture)", completion: { error in
                                            
            if error != nil { return }
            else { self.tableView.reloadData() }
        })
    }
    
    // TODO: In future update, this can maybe be refactored into custom UIImageView
    /** Selector method which triggers a prompt for a UIImagePickerController. */
    func promptImageSelection() {
     
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
    
    
    /** Dismiss the keyboard from screen if currently displayed. */
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    
    /** Determines actions to perform when a user chooses to logout. */
    func logout() {
        
        // Present a confirmation dialog to logout
        let ac = UIAlertController(title: "Confirm Logout", message: Constants.Messages.confirmLogout, preferredStyle: .alert)
        ac.view.tintColor = Constants.Colors.primaryDark
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        ac.addAction(UIAlertAction(title: "Logout", style: .default, handler: { (action) in
            
            do {
                // Attempt to logout, may throw error
                try Auth.auth().signOut()
                
                // At this point, signOut() succeeded by not throwing any errors
                // Let AuthController perform account sign out maintenance
                
                AuthController.signOut()
                self.performSegue(withIdentifier: Constants.Segues.unwindToSignInSegue, sender: self)
                
            } catch let error as NSError {
                print("AtMe:: \(error.localizedDescription)")
            }
        }))
        
        // Present the alert
        self.present(ac, animated: true, completion: nil)
    }
    
    
    /** Overridden method providing an opportunity for data transfer to destination view controller before segueing to it. */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Constants.Segues.showPromptSegue {
            if let destination = segue.destination as? PromptViewController {
                var attributeIndex: Int = 0
                
                // Based on which section was selected, extract the correct UserAttribute from enum
                // TODO: In future, should find cleaner solution for this
                
                if (tableView.indexPathForSelectedRow!.section == 1) {
                    attributeIndex = tableView.indexPathForSelectedRow!.row + 1
                } else if (tableView.indexPathForSelectedRow!.section == 2) {
                    attributeIndex = tableView.indexPathForSelectedRow!.row + 3
                }
                
                destination.changingAttribute = Constants.UserAttribute(rawValue: attributeIndex)!
                destination.changingAttributeName = Constants.UserAttributes.UserAttributeNames[attributeIndex]
            }
        }
    }
}


// MARK: - Image Picker Delegate Methods
extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // TODO: In future update, refactor
    /** Called when media has been selected by the user in the image picker. */
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // Immediately dismiss for responsiveness
        dismiss(animated: true)
        
        let uid = UserState.currentUser.uid
        let path = "displayPictures/\(uid)/\(uid).JPG"
        
        // Extract the image after editing, upload to database as Data object
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            if let data = convertImageToData(image: image) {
                
                DatabaseController.uploadImage(data: data, to: path, completion: { (error) in
                    if let error = error {
                        print("AtMe:: Error uploading display picture to Firebase. \(error.localizedDescription)")
                        return
                    }
                    
                    self.updateUserDisplayPicture()
                })
                
            } else { print("AtMe:: Error extracting image from camera source") }
        } else { print("AtMe:: Error extracting edited UIImage from info dictionary") }
    }
    
    
    /** Called if and when the user has cancelled the image picking operation. */
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}



// MARK: - Table View
extension SettingsViewController {
    
    /** Called when a given row / index path is selected in the table view. */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Tapped \(indexPath)")
        // Opting to change editable user attributes prompts PromptViewController
        if (indexPath.section == 1 || indexPath.section == 2) {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: Constants.Segues.showPromptSegue, sender: self)
            }
        }
            
        // Handle cache removal request
        if (indexPath.section == 3) {
            if (indexPath.row == 0) {
                DatabaseController.clearCachedImages()
                presentSimpleAlert(title: "Cache Cleared", message: Constants.Messages.cacheClearedSuccess, completion: nil)
            }
        }
        
        // Initiate logout
        else if (indexPath.section == 4 && indexPath.row == 0) {
            logout()
        }
    }
}
