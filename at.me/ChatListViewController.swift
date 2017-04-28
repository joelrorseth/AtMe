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
    private lazy var conversationsRef: FIRDatabaseReference = FIRDatabase.database().reference().child("conversations")
    
    var conversations: [Conversation] = []
    
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
        
        // On a background thread, dispatch a queue to handle populating list of conversations
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            
            self.loadActiveConvoIds(completion: {
                self.loadDetailForConvos()
                self.tableView.reloadData()
            })
        }
        
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
        return conversations.count
    }
    
    // ==========================================
    // ==========================================
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatListCell", for: indexPath) as! ConversationCell
        
        // Extract details from conversations retrieved
        
        cell.nameLabel.text = conversations[indexPath.row].otherUsername
        cell.recentMessageLabel.text = conversations[indexPath.row].newestMessage
        cell.recentMessageTimeStampLabel.text = conversations[indexPath.row].newestMessageTimeStamp
        
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
            // Delete current user's reference to convo, then decrement number of members in convo
            
            userConversationListRef.child(UserState.currentUser.uid!).child(conversations[indexPath.row].otherUsername).removeValue()
            
            // Extract conversation unique id and Firebase ref to activeMembers record
            let convoId = conversations[indexPath.row].convoId
            let activeMembersRef = conversationsRef.child("\(convoId)/activeMembers")
            
            activeMembersRef.observeSingleEvent(of: .value, with: { snapshot in
                
                // Decrement value since current user is leaving convo
                let membersCount = (snapshot.value as? Int)! - 1
                
                // If no members left in convo, delete the conversation entirely!
                if (membersCount == 0) {
                    
                    // Delete conversation
                    self.conversationsRef.child(convoId).removeValue()
                    
                } else {
                    
                    // Otherwise, just decrement number of convo members
                    activeMembersRef.setValue(membersCount)
                }
            })
            
            
            // Also remove records from local table view data source
            conversations.remove(at: indexPath.row)
            
            // Delete row in tableView
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.right)
            tableView.reloadData()
        }
    }
    
    // ==========================================
    // ==========================================
    private func loadActiveConvoIds(completion: @escaping (Void) -> Void) {
        
        // Establish the current active conversations to populate the table view data source
        userConversationListRef.child(UserState.currentUser.uid!).queryOrderedByKey().observe(.value, with: { snapshot in
            
            // Clear current list of convos
            self.conversations.removeAll()
            
            for convoRecord in snapshot.children {
                let convoSnapshot = convoRecord as! FIRDataSnapshot
                
                // Create and store (partially incomplete) Conversation object
                // These objects will provide all info needed for table cells
                
                self.conversations.append(
                    Conversation(
                        convoId: convoSnapshot.value as! String,
                        otherUsername: convoSnapshot.key,
                        newestMessage: "",
                        newestMessageTimeStamp: ""
                    )
                )
            }

            completion()
        })
    }
    
    // ==========================================
    // ==========================================
    private func loadDetailForConvos() {
        
//        // Load most recent message and timestamp
//        conversationsRef.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
//            
//            for activeConvo in self.conversations {
//                
//                // TODO: Load newest message and timestamp
//                // Come back to this once messaging has been hooked up
//                
//                let convoSnapshot = snapshot.childSnapshot(forPath: activeConvo.convoId)
//                
//                //activeConvo.newestMessage = convoSnapshot ...
//                //activeConvo.newestMessageTimeStamp = convoSnapshot ...
//            }
//        })
    }
    
    
    // MARK: Segue
    // ==========================================
    // ==========================================
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == Constants.Segues.loadConvoSegue) {
            let cvc = segue.destination as! ConvoViewController
            
            // Get the index path of selected row that triggered segue
            // The rows correspond directly with ordering in table view
            // Pass along convoId of selected conversation
            
            let indexPath = tableView.indexPathForSelectedRow
            let selectedConvoId = conversations[(indexPath?.row)!].convoId
            
            cvc.messagesRef = conversationsRef.child("\(selectedConvoId)/messages")
            cvc.convoId = selectedConvoId
        }
    }
    
    
    // MARK: Functionality
    // ==========================================
    // ==========================================
    @objc private func didTapSettings() {
        self.performSegue(withIdentifier: "ShowSettings", sender: self)
    }
}
