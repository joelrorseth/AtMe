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
    lazy var userConversationListRef: FIRDatabaseReference = FIRDatabase.database().reference().child("userConversationList")
    lazy var conversationsRef: FIRDatabaseReference = FIRDatabase.database().reference().child("conversations")
    
    // Firebase handles
    private var messageHandles: [FIRDatabaseHandle] = []
    
    // Local Conversation cache
    var conversations: [Conversation] = []
    
    // TODO: Sort conversations newest at the top
    // TODO: Store timestamp with more precision (NSDate?)
    
    
    
    // MARK: View
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set translucent navigation bar with color
        let image = UIImage.imageFromColor(color: Constants.Colors.primaryColor)
        self.navigationController?.navigationBar.setBackgroundImage(image, for: UIBarMetrics.default)
        self.navigationController?.navigationBar.barStyle = .default
        
        //self.navigationController?.hidesBarsOnSwipe = true
        
        self.tableView.backgroundColor = UIColor.groupTableViewBackground
        
        
        // Establish bar button items in conversations view
        let settingsIcon = UIImage(named: "settings")
        let settingsButton = UIBarButtonItem(image: settingsIcon, style: .plain, target: self, action: #selector(didTapSettings))
        
        self.navigationItem.leftBarButtonItem = settingsButton
        self.navigationItem.title = "@Me"
        
        // On a background thread, dispatch a queue to handle populating list of conversations
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            
            self.loadActiveConvoIds(completion: {
                self.loadDetailForConvos()
                self.tableView.reloadData()
            })
        }
    }
    
    // ==========================================
    // ==========================================
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Set the back button in the vc being pushed to have no text
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    

    // MARK: Loading and formatting
    // ==========================================
    // ==========================================
    func formatConversationCell(cell: ConversationCell) {
        
        // Draw shadow behind nested view to give cells some depth
        let shadowSize : CGFloat = 3.0
        let shadowPath = UIBezierPath(
            rect: CGRect(x: -shadowSize / 2,
                         y: -shadowSize / 2,
                         width: cell.cellBackgroundView.frame.size.width + shadowSize,
                         height: cell.cellBackgroundView.frame.size.height + shadowSize))
        
        cell.cellBackgroundView.layer.masksToBounds = false
        cell.cellBackgroundView.layer.shadowOffset = CGSize(width: 0, height: 1.4)
        cell.cellBackgroundView.layer.shadowColor = UIColor.lightGray.cgColor
        cell.cellBackgroundView.layer.shadowOpacity = 0.7
        cell.cellBackgroundView.layer.shadowRadius = 0.0
        cell.cellBackgroundView.layer.shadowPath = shadowPath.cgPath
        
        // Give display picture a circular mask
        cell.userDisplayImageView.layer.masksToBounds = true;
        cell.userDisplayImageView.layer.cornerRadius = cell.userDisplayImageView.frame.width / 2
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
                        newestMessageTimestamp: ""
                    )
                )
            }

            completion()
        })
    }
    
    // ==========================================
    // ==========================================
    private func loadDetailForConvos() {

        // Add one observer for each convo to notify when new messages appear
        for conversation in conversations {
            
            // For each observer, add the corresponding handle into array of handles
            messageHandles.append(
                
                // Query the most recent message record for each conversation loaded previously
                // This block is called for each new message detected thereafter
                
                conversationsRef.child("\(conversation.convoId)/messages").queryLimited(toLast: 1)
                    .observe(FIRDataEventType.childAdded, with: { (snapshot) in

                        conversation.newestMessageTimestamp = snapshot.childSnapshot(forPath: "timestamp").value as! String
                        
                        // Extract the new message, set as the current convo's newest message!
                        if let text = snapshot.childSnapshot(forPath: "text").value as? String {
                            conversation.newestMessage = text
                        } else if let _ = snapshot.childSnapshot(forPath: "imageURL").value {
                            conversation.newestMessage = "Picture Message"
                        }
                        
                        // TODO: Possibly refactor to avoid reloading every time?
                        self.tableView.reloadData()
                    })
            )
        }
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
            
            if let indexPath = tableView.indexPathForSelectedRow {
                let selectedConvoId = conversations[indexPath.row].convoId
                
                cvc.messagesRef = conversationsRef.child("\(selectedConvoId)/messages")
                cvc.convoId = selectedConvoId
                
                // Pass the username selected to the title of convo
                if let selectedUsername = (tableView.cellForRow(at: indexPath) as! ConversationCell).nameLabel.text {
                    cvc.navigationItem.title = selectedUsername
                }
            }
        }
    }
    
    
    // MARK: Functionality
    // ==========================================
    // ==========================================
    @objc private func didTapSettings() {
        self.performSegue(withIdentifier: "ShowSettings", sender: self)
    }
    
    // ==========================================
    // ==========================================
    deinit {

        // For each handle, remove observer for incoming messages
        // TODO: Refactor for neat method of removing all observers added
        
        for handle in messageHandles {
            conversationsRef.removeObserver(withHandle: handle)
            print("AT.ME:: Removed observer with handle \(handle) in ChatListViewController")
        }
    }
}


// MARK: Table View
extension ChatListViewController {
    
    // MARK: Table View
    // ==========================================
    // ==========================================
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // ==========================================
    // ==========================================
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(116)
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
        
        formatConversationCell(cell: cell)
        
        // Update the sender, newest message, and timestamp from this conversation
        cell.nameLabel.text = conversations[indexPath.row].otherUsername
        cell.recentMessageLabel.text = conversations[indexPath.row].newestMessage
        cell.recentMessageTimeStampLabel.text = conversations[indexPath.row].newestMessageTimestamp
        
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
}
