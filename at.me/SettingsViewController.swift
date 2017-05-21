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
    }
    
    // ==========================================
    // ==========================================
    override func viewWillAppear(_ animated: Bool) {
        print("at.me:: Settings screen appeared, loading user information...")
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
        
        self.tableView.reloadData()
    }
    
    // ==========================================
    // ==========================================
    func updateUserDisplayPicture(image: UIImage) {
        
        if let uid = UserState.currentUser.uid {
            let path = "\(uid)/\(uid).JPG"
            self.userInformationRef.child("\(uid)/displayPicture").setValue(path)
        } else {
            print("AT.ME:: Could not determine current user uid to update display picture")
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
                var attributeIndex: Int = 0
                
                // Based on which section was selected, extract the correct UserAttribute from enum
                if (tableView.indexPathForSelectedRow!.section == 1) {
                    attributeIndex = tableView.indexPathForSelectedRow!.row + 1
                } else if (tableView.indexPathForSelectedRow!.section == 2) {
                    attributeIndex = tableView.indexPathForSelectedRow!.row + 4
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
        
        // TODO: Save edited image
        // TODO: Cache image
        
        guard let uid = UserState.currentUser.uid else { return }
        let path = "\(uid)/\(uid).JPG"
        
        if let urlString = info[UIImagePickerControllerReferenceURL] as? String {
            
            // Case 1: Image was selected from photo library
            if let url = extractLibraryImage(from: urlString) {
                DatabaseController.uploadLibraryImage(url: url, to: self.userDisplayPictureRef.child(path), completion: { (error) in
                    if let error = error {
                        print("AT.ME:: Error uploading display picture to Firebase \(error.localizedDescription)")
                        return
                    }
                    
                    // TODO: Cache new profile picture, update UserState.currentUser
                    // Have to figure out how to load picture using URL
                    
                    print("AT.ME:: Image uploaded successfully")
                    self.userInformationRef.child("\(uid)/displayPicture").setValue(path)
                })
            } else { print("AT.ME:: Error extracting image from library") }
        } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            // Case 2: Image was taken by camera
            if let data = extractCameraImage(image: image) {
                DatabaseController.uploadCameraImage(data: data, to: userDisplayPictureRef.child(path), completion: { (error) in
                    if let error = error {
                        print("AT.ME:: Error uploading display picture to Firebase \(error.localizedDescription)")
                        return
                    }
                    
                    print("AT.ME:: Image uploaded successfully")
                    self.updateUserDisplayPicture(image: image)
                })
            } else { print("AT.ME:: Error extracting image from camera source") }
        } else { print("AT.ME:: Error extracting selected photo from UIImagePickerController") }

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
                self.performSegue(withIdentifier: "ShowPrompt", sender: self)
            }
        }
        
        // Initiate logout
        else if (indexPath.section == 3 && indexPath.row == 0) {
            logout()
        }
    }
}
