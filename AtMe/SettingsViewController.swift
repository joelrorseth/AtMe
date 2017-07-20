//
//  SettingsViewController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-03-01.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Photos
import Firebase

class SettingsViewController: UITableViewController, AlertController {
    
    lazy var userInformationRef: DatabaseReference = Database.database().reference().child("userInformation")
    
    internal let databaseManager = DatabaseController()
    
    var currentAttributeChanging: Constants.UserAttribute = Constants.UserAttribute.none
    var attributePrompt: String = ""

    @IBOutlet weak var userPictureImageView: UIImageView!
    @IBOutlet weak var userDisplayNameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var logoutCell: UITableViewCell!
    
    
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add gesture recognizer to the profile picture UIImageView
        let imageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SettingsViewController.promptImageSelection))
        
        userPictureImageView.addGestureRecognizer(imageGestureRecognizer)
        userPictureImageView.isUserInteractionEnabled = true
    }
    
    // ==========================================
    // ==========================================
    override func viewWillAppear(_ animated: Bool) {
        loadCurrentUserInformation()
        
        logoutCell.backgroundColor = Constants.Colors.primaryDark
        userPictureImageView.layer.masksToBounds = true
        userPictureImageView.clipsToBounds = true
        userPictureImageView.layer.cornerRadius = userPictureImageView.frame.size.width / 2
    }
    
    // ==========================================
    // ==========================================
    func updateUserDisplayPicture(image: UIImage) {
        
        let uid = UserState.currentUser.uid
        let url = "\(uid)/\(uid).JPG"
        
        UserState.currentUser.displayPicture = url
        userInformationRef.child("\(uid)/displayPicture").setValue(url)
        
        // Update current user stored display picture, reload image view
        loadCurrentUserInformation()
    }
    
    // ==========================================
    // ==========================================
    private func loadCurrentUserInformation() {
        
        // Should never happen, app blocks until these have been set at login
        userDisplayNameLabel.text = UserState.currentUser.name
        usernameLabel.text = "@" + UserState.currentUser.username
        
        guard let picture = UserState.currentUser.displayPicture else {
            presentSimpleAlert(title: "Could Not Set Picture", message: Constants.Errors.displayPictureMissing, completion: nil)
            return
        }
        
        // Display picture may very well be nil if not set or loaded yet
        // This is because display pictures are loaded asynchronously at launch
        
        databaseManager.downloadImage(into: userPictureImageView,
            from: "displayPictures/\(picture)", completion: { error in
                                            
            if error != nil { return }
            else { self.tableView.reloadData() }
        })
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
    func logout() {
        
        // Present a confirmation dialog to logout
        let ac = UIAlertController(title: "Confirm Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        ac.view.tintColor = Constants.Colors.primaryDark
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        ac.addAction(UIAlertAction(title: "Logout", style: .default, handler: { (action) in
            
            do {
                // Attempt to logout, may throw error
                try Auth.auth().signOut()
                
                // At this point, signOut() succeeded by not throwing any errors
                self.performSegue(withIdentifier: Constants.Segues.unwindToSignInSegue, sender: self)
                
            } catch let error as NSError {
                print("AtMe:: \(error.localizedDescription)")
            }
            
            // TODO: Remove ALL observers
        }))
        
        // Present the alert
        self.present(ac, animated: true, completion: nil)
    }
    
    // ==========================================
    // ==========================================
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


// MARK: Image Picker Delegate Methods
extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // ==========================================
    // ==========================================
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let uid = UserState.currentUser.uid
        let path = "displayPictures/\(uid)/\(uid).JPG"
        
        // Extract the image after editing, upload to database as Data object
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            if let data = convertImageToData(image: image) {
                
                databaseManager.uploadImage(data: data, to: path, completion: { (error) in
                    if let error = error {
                        print("AtMe:: Error uploading display picture to Firebase. \(error.localizedDescription)")
                        return
                    }
                    
                    self.updateUserDisplayPicture(image: image)
                })
                
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



// MARK: Table View
extension SettingsViewController {
    
    // ==========================================
    // ==========================================
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Opting to change editable user attributes prompts PromptViewController
        if (indexPath.section == 1 || indexPath.section == 2) {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: Constants.Segues.showPromptSegue, sender: self)
            }
        }
            
        // Handle cache removal request
        if (indexPath.section == 3) {
            if (indexPath.row == 0) {
                databaseManager.clearCachedImages()
            }
        }
        
        // Initiate logout
        else if (indexPath.section == 4 && indexPath.row == 0) {
            logout()
        }
    }
}
