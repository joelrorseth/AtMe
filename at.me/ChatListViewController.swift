//
//  ChatListViewController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-02-18.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

class ChatListViewController: UITableViewController {
    
    // Firebase references are used for read/write at referenced location
    lazy var userConversationListRef: DatabaseReference = Database.database().reference().child("userConversationList")
    lazy var conversationsRef: DatabaseReference = Database.database().reference().child("conversations")
    lazy var rootDatabaseRef: DatabaseReference = Database.database().reference()
    lazy var userDisplayPictureRef: StorageReference = Storage.storage().reference().child("displayPictures")
    
    // Firebase handles
    private var messageHandles: [DatabaseHandle] = []
    
    // Local Conversation cache
    var conversations: [Conversation] = []
    
    // TODO: Sort conversations newest at the top
    // TODO: Store timestamp with more precision (NSDate?)
    
    
    
    // MARK: View
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: Refactor cache clearing into Settings menu option
        // Add code to intelligently delete from cache (come up with nested naming convention?)
        //ImageCache.default.clearDiskCache()
        ImageCache.default.calculateDiskCacheSize { (size) in print("Used disk size by bytes: \(size)") }
        
        setupView()
        self.setNeedsStatusBarAppearanceUpdate()
        
        // Start the observers
        observeConversations()
    }
    
    // ==========================================
    // ==========================================
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Set the back button in the vc being pushed to have no text
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    // ==========================================
    // ==========================================
    private func setupView() {
        
        // Set translucent navigation bar with color
        let image = UIImage.imageFromColor(color: Constants.Colors.primaryColor)
        self.navigationController?.navigationBar.setBackgroundImage(image, for: UIBarMetrics.default)
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        
        // Set background color appearing behind the cells
        self.tableView.backgroundColor = UIColor.groupTableViewBackground
        
        
        // Establish bar button items in conversations view
        let settingsIcon = UIImage(named: "settings")
        let settingsButton = UIBarButtonItem(image: settingsIcon, style: .plain, target: self, action: #selector(didTapSettings))
        settingsButton.tintColor = UIColor.white
        
        self.navigationItem.leftBarButtonItem = settingsButton
        self.navigationItem.title = "@Me"
    }
    
    // ==========================================
    // ==========================================
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    
    // MARK: Formatting
    // ==========================================
    // ==========================================
    func formatConversationCell(cell: ConversationCell) {
        
        // TODO: Refactor shadown code to use shadowPath (more efficient)
//        // Draw shadow behind nested view to give cells some depth
//        let shadowSize : CGFloat = 3.0
//        let shadowPath = UIBezierPath(
//            rect: CGRect(x: -shadowSize / 2,
//                         y: -shadowSize / 2,
//                         width: cell.cellBackgroundView.frame.size.width + shadowSize,
//                         height: cell.cellBackgroundView.frame.size.height + shadowSize))
//        
//        cell.cellBackgroundView.layer.shadowPath = shadowPath.cgPath
        
        cell.cellBackgroundView.layer.masksToBounds = false
        cell.cellBackgroundView.layer.shadowOffset = CGSize(width: 0, height: 1.4)
        cell.cellBackgroundView.layer.shadowColor = UIColor.lightGray.cgColor
        cell.cellBackgroundView.layer.shadowOpacity = 0.7
        cell.cellBackgroundView.layer.shadowRadius = 2.4
        cell.cellBackgroundView.layer.cornerRadius = Constants.Radius.regularRadius
        
        // Give display picture a circular mask
        cell.userDisplayImageView.layer.masksToBounds = true;
        cell.userDisplayImageView.layer.cornerRadius = cell.userDisplayImageView.frame.width / 2
    }
    
    // MARK: Loading
    // ==========================================
    // ==========================================
    private func observeConversations() {
        
        // TODO: Refactor UserState to make everything non-optional
        // TODO: Exiting chat to this screen does not update newest message
        if let uid = UserState.currentUser.uid {
            
            // Call this closure once for every conversation record, and any time a record is added
            userConversationListRef.child(uid).keepSynced(true)
            userConversationListRef.child(uid).observe(DataEventType.childAdded, with: { snapshot in
                
                let otherUsername = snapshot.key
                if let convoId = snapshot.value as? String {
                    
                    self.addConversation(convoId: convoId, with: otherUsername)
                }
            })
        }
    }
    
    // ==========================================
    // ==========================================
    private func addConversation(convoId: String, with username: String) {
        
        self.conversationsRef.child("\(convoId)/").observeSingleEvent(of: .value, with: { (snapshot) in
            if ((snapshot.childSnapshot(forPath: "messagesCount").value as! Int) == 0) {
                // Convo has no messages
                
                // Insert placeholder to prompt user to start the conversation
                self.insertConversationCell(conversation:
                    Conversation(convoId: convoId,
                                 otherUsername: username,
                                 newestMessage: "This is the beginning of your conversation with \(username)",
                                 newestMessageTimestamp: ""))
                
            } else {
                // Convo has messages
                
                // TODO: Possibly switch design to store a most recent message in the convo record
                // This would avoid querying every time, but would take more space and work require
                // updating this every time a message is ever sent
                
                // Retrieve a snapshot for the most recent message record in this conversation
                self.conversationsRef.child("\(convoId)/messages").queryLimited(toLast: 1)
                    .observe(DataEventType.childAdded, with: { (snapshot) in
                        
                        let timestamp = snapshot.childSnapshot(forPath: "timestamp").value as! String
                        var message = "This is the beginning of your conversation with \(username)"
                        
                        // Extract the new message, set as the current convo's newest message!
                        // If picture message, don't load, but let user know it was a picture message
                        
                        if let text = snapshot.childSnapshot(forPath: "text").value as? String { message = text }
                        else if let _ = snapshot.childSnapshot(forPath: "imageURL").value { message = "Picture Message" }
                        
                        
                        // If conversation has already been created, simply update message displayed instead of making new convo
                        // TODO: Find better way
                        
                        for convo in self.conversations {
                            if (convo.otherUsername == username) {
                                convo.newestMessage = message
                                convo.newestMessageTimestamp = timestamp
                                
                                self.tableView.reloadData()
                                return
                            }
                        }
                        
                        self.insertConversationCell(conversation:
                            Conversation(convoId: convoId,
                                         otherUsername: username,
                                         newestMessage: message,
                                         newestMessageTimestamp: timestamp))
                        
                    })
            }
        })
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
                
                //print("AT.ME:: Setting messagesRef from ChatListViewController!")
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
    
    // ==========================================
    // ==========================================
    func insertConversationCell(conversation: Conversation) {
        
        // Insert the object into the data source
        self.conversations.append(conversation)
        
        // Efficiently update by updating / inserting only the cells that need to be
        self.tableView.beginUpdates()
        self.tableView.insertRows(at: [IndexPath(row: self.conversations.count - 1, section: 0)], with: .left)
        self.tableView.endUpdates()
    }
    
    // ==========================================
    // ==========================================
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // ==========================================
    // ==========================================
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(94)
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
        
        
        // TODO: Refactor Conversation class to hold the uid of the other user
        // This way, don't need to lookup uid and can access storage reference right away
        
        rootDatabaseRef.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            
            if let uid = snapshot.childSnapshot(forPath: "registeredUsernames/\(self.conversations[indexPath.row].otherUsername)").value as? String {
                if let _ = snapshot.childSnapshot(forPath: "userInformation/\(uid)/displayPicture").value as? String {
                    
                    DatabaseController.downloadImage(into: cell.userDisplayImageView, from: self.userDisplayPictureRef.child("\(uid)/\(uid).JPG") , completion: { (error) in
                        
                        if let downloadError = error {
                            print("At.ME:: An error has occurred, but image data was detected. \(downloadError)")
                            return
                        }
                        
                        print("At.ME:: Image data was downloded and converted successfully")                            
                        
                    })
                    
                } else { print("AT.ME:: This user does not have a display picture") }
            }
        })
        
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
