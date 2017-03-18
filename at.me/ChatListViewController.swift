//
//  ChatListViewController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-02-18.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase

class ChatListViewController: UITableViewController {
    
    // Firebase references are used for read/write at referenced location
    private lazy var userConversationListRef: FIRDatabaseReference = FIRDatabase.database().reference().child("userConversationList")
    
    // TODO: Refactor these two arrays into enumerable array of tuples or other data structure
    var activeConversations: [String] = []
    var activeConversationsUIDs: [String] = []
    
    // MARK: View
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set table view properties
        tableView.tintColor = Constants.Colors.primaryColor
        
        // Establish bar button items in conversations view
        let settingsIcon = UIImage(named: "settings")
        let settingsButton = UIBarButtonItem(image: settingsIcon, style: .plain, target: self, action: #selector(didTapSettings))
        

        self.navigationItem.leftBarButtonItem = settingsButton
        self.navigationItem.title = "@ Me"
        
        // Establish the current active conversations to populate the table view data source
        let currentUserUid = FIRAuth.auth()?.currentUser?.uid
        
        userConversationListRef.child(currentUserUid!).queryOrderedByKey().observe(.value, with: { snapshot in
            
            // Clear current list of convos
            self.activeConversations.removeAll()
            
            for item in snapshot.children {
                let convo = item as! FIRDataSnapshot
                
                // TODO: Change db model to store username in each conversation record value
                print("Child key for user is \(convo.key), value is \(convo.value as! String)")
                
                // Add username and uid into table view data sources
                self.activeConversations.append("\(convo.value as! String)")
                self.activeConversationsUIDs.append("\(convo.key)")
            }

            self.tableView.reloadData()
        })
    }
    
    
    // MARK: Table View
    // ==========================================
    // ==========================================
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // ==========================================
    // ==========================================
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(80)
    }
    
    // ==========================================
    // ==========================================
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activeConversations.count
    }
    
    // ==========================================
    // ==========================================
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatListCell", for: indexPath) as! ConversationCell
        
        // TODO: Obtain most recent message for detail text
        cell.nameLabel.text = activeConversations[indexPath.row]
        cell.recentMessageLabel.text = "Need to come back here to add the most recent message in future update."
        cell.recentMessageTimeStampLabel.text = "12:34 PM"
        //cell.userDisplayImageView.image =
        
        return cell
    }
    
    // ==========================================
    // ==========================================
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // ==========================================
    // ==========================================
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        // Handle the user deleting a conversation
        // In Firebase, delete only the current users record of being in this conversation
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            
            // Update records in Firebase
            let currentUserUid = (FIRAuth.auth()?.currentUser?.uid)!
            userConversationListRef.child(currentUserUid).child(activeConversationsUIDs[indexPath.row]).removeValue()
            
            // Also remove records from local table view data source
            activeConversations.remove(at: indexPath.row)
            activeConversationsUIDs.remove(at: indexPath.row)
            
            // Delete row in tableView
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.right)
            tableView.reloadData()
        }
    }
    
    
    
    // MARK: Functionality
    // ==========================================
    // ==========================================
    @objc private func didTapSettings() {
        
        self.performSegue(withIdentifier: "ShowSettings", sender: self)
    }
}
