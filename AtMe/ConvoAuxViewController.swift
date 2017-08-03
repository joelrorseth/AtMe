//
//  ConvoAuxViewController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-08-01.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

class ConvoAuxViewController: UIViewController, AlertController {

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
            AuthController.blockUser(uid: uid, username: username)
            DatabaseController.leaveConversation(convoID: convoID, with: username, completion: {
                self.performSegue(withIdentifier: "UnwindToChatListSegue", sender: nil)
            })
        })
    }

    
    /** Handle user pressing the Report User button. */
    @IBAction func didPressReportUserButton(_ sender: Any) {
        guard let uid = self.uid, let username = self.username else { return }
        
        // Just to test, print blocked status and unblock
        AuthController.userOrCurrentUserHasBlocked(uid: uid, username: username, completion: { blocked in
            print(blocked)
        })
        
        AuthController.unblockUser(uid: uid, username: username)
    }
    
    
    /** Method called when view is loaded onto screen. */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let uid = self.uid, let username = self.username else {
            presentSimpleAlert(title: "Error Loading Profile", message: Constants.Errors.loadProfileError, completion: { _ in
                self.dismiss(animated: true, completion: nil)
            })
            return
        }
        
        DatabaseController.downloadImage(into: displayPictureImageView, from: "displayPictures/\(uid)/\(uid).JPG", completion: { _ in
            self.displayPictureImageView.layer.masksToBounds = true
            self.displayPictureImageView.layer.cornerRadius = self.displayPictureImageView.frame.size.width / 2
        })
        
        AuthController.findNameFor(uid: uid, completion: { name in
            if let name = name { self.nameLabel.text = name }
        })

        blockUserButton.layer.cornerRadius = Constants.Radius.regularRadius
        reportUserButton.layer.cornerRadius = Constants.Radius.regularRadius
        
        usernameLabel.text = "@\(username)"
    }
}
