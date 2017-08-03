//
//  BlockedUsersViewController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-08-03.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

class BlockedUsersViewController: UITableViewController {

    var blockedUsers: [UserProfile] = []
    
    
    /**
     Called when the view is done loading in the view controller.
    */
    override func viewDidLoad() {
        super.viewDidLoad()

        // Immediately ask AuthController for blocked users to populate
        // Insert these into table view directly since it will return asynchronously
        
        AuthController.findCurrentUserBlockedUsers(completion: { user in
            self.blockedUsers.append(user)
            self.tableView.insertRows(at: [IndexPath(row: self.blockedUsers.count - 1, section: 0)], with: .automatic)
        })

        // Set table view attributes
        self.title = "Blocked"
        tableView.tableFooterView = UIView()
    }
    

    // MARK: - Table view
    /**
     Determine the number of sections in the table view.
    */
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    
    /**
     Determine the number of rows in a given section of the table view.
    */
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedUsers.count
    }

    
    /**
     Determine the contents of a table view cell at a given index path.
    */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.CellIdentifiers.blockedUserCell, for: indexPath) as! BlockedUserCell

        // Important: Set delegate for button so this view controller knows about taps
        cell.blockUserCellDelegate = self
        cell.unblockButton.layer.cornerRadius = Constants.Radius.regularRadius
        
        // Extract user info from relevant data source record
        cell.nameLabel.text = blockedUsers[indexPath.row].name
        cell.usernameLabel.text = "@" + blockedUsers[indexPath.row].username
        
        let uid = blockedUsers[indexPath.row].uid
        let path = "displayPictures/\(uid)/\(uid).JPG"
        
        
        // Also important: Set uid and username for use in the cell delegate
        cell.uid = uid
        cell.username = blockedUsers[indexPath.row].username
        
        
        // Download the image into the display picture image view
        DatabaseController.downloadImage(into: cell.displayPictureImageView, from: path, completion: { _ in
            cell.displayPictureImageView.layer.masksToBounds = true
            cell.displayPictureImageView.layer.cornerRadius = cell.displayPictureImageView.frame.size.width / 2
        })

        return cell
    }
}

extension BlockedUsersViewController: BlockedUserCellDelegate {
 
    /**
     Handle unblocking the selected user and removing them from the table.
     - parameters:
        - button: A reference to the button which was selected to trigger this change.
        - uid: The uid of the user selected to be unblocked.
        - username: The username of the user selected to be unblocked.
    */
    func didTapUnblock(button: UIButton, uid: String, username: String) {
        
        UIView.animate(withDuration: 0.2, animations: {
            button.backgroundColor = UIColor.groupTableViewBackground
            button.alpha = 0.0
        
        }, completion: { _ in

            // Unblock the user and remove that row from table and data source
            AuthController.unblockUser(uid: uid, username: username)
            
            for (index, user) in self.blockedUsers.enumerated() {
                if (uid == user.uid) {
                    self.blockedUsers.remove(at: index)
                    self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                }
            }
        })
    }
}
