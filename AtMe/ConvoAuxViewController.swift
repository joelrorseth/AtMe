//
//  ConvoAuxViewController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-08-01.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

class ConvoAuxViewController: UIViewController, AlertController {
    
    lazy var databaseManager = DatabaseController()
    lazy var authManager = AuthController()
    
    var username: String?
    var convoID: String?
    var uid: String?
    
    @IBOutlet var displayPictureImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var blockUserButton: UIButton!
    @IBOutlet var reportUserButton: UIButton!
    
    
    /** Handle user pressing the Block User button. */
    @IBAction func didPressBlockUserButton(_ sender: UIButton) {
        guard let uid = self.uid, let convoID = self.convoID, let username = self.username else { return }
        
        presentConfirmationAlert(title: "Confirm Block", message: Constants.Messages.confirmBlockMessage, completion: { _ in
            
            // Add user to current user's blocked list, leave conversation
            self.authManager.blockUser(uid: uid, username: username)
            self.databaseManager.leaveConversation(convoID: convoID, with: username, completion: {
                self.performSegue(withIdentifier: "UnwindToChatListSegue", sender: nil)
            })
        })
    }

    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set display picture frame to circle (need this for default image especially)
        self.displayPictureImageView.layer.masksToBounds = true
        self.displayPictureImageView.layer.cornerRadius = self.displayPictureImageView.frame.size.width / 2
    }
    
    
    /** Method called when view is loaded onto screen. */
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // Set display picture frame to circle (need this for default image especially)
        self.displayPictureImageView.layer.cornerRadius = self.displayPictureImageView.frame.size.width / 2
        
        guard let uid = self.uid, let username = self.username else {
            presentSimpleAlert(title: "Error Loading Profile", message: Constants.Errors.loadProfileError, completion: { _ in
                self.dismiss(animated: true, completion: nil)
            })
            return
        }
        
        
        // Download display picture into large central image view
        databaseManager.downloadImage(into: displayPictureImageView, from: "displayPictures/\(uid)/\(uid).JPG", completion: { _ in
            self.displayPictureImageView.layer.masksToBounds = true
            self.displayPictureImageView.layer.cornerRadius = self.displayPictureImageView.frame.size.width / 2
        })
        
        // Set the name of user
        authManager.findNameFor(uid: uid, completion: { name in
            if let name = name { self.nameLabel.text = name }
        })
        
        
        // In case user has already blocked this user, disable
        authManager.userOrCurrentUserHasBlocked(uid: uid, username: username, completion: { blocked in
            
            if blocked {
                self.blockUserButton.isEnabled = false
                self.blockUserButton.isUserInteractionEnabled = false
                self.blockUserButton.backgroundColor = UIColor.lightGray
                self.blockUserButton.setTitle("Already Blocked", for: .normal)
            }
        })

        blockUserButton.layer.cornerRadius = Constants.Radius.regularRadius
        reportUserButton.layer.cornerRadius = Constants.Radius.regularRadius
        
        usernameLabel.text = "@\(username)"
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Constants.Segues.reportUserSegue {
            let vc = segue.destination as! ReportUserViewController
            
            // Pass in details about user whom is being reported
            if let uid = self.uid, let username = self.username, let convoID = self.convoID {
             
                vc.violatorUid = uid
                vc.violatorUsername = username
                vc.convoID = convoID
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == Constants.Segues.reportUserSegue {
            
            // Make sure optionals can be unwrapped before segue is performed
            if let _ = self.uid, let _ = self.username, let _ = self.convoID { return true }
            else { return false }
        }
        
        return true
    }
}
