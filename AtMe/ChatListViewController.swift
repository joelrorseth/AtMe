//
//  ChatListViewController.swift
//  AtMe
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
    lazy var userInactiveConversationsRef: DatabaseReference = Database.database().reference().child("userInactiveConversations")
    lazy var conversationsRef: DatabaseReference = Database.database().reference().child("conversations")
    lazy var rootDatabaseRef: DatabaseReference = Database.database().reference()
    
    internal let databaseManager = DatabaseController()
    
    // Local Conversation cache
    var conversations: [Conversation] = []
    var conversationIndexes: [String : Int] = [:]
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.none
        formatter.timeStyle = DateFormatter.Style.short
        
        return formatter
    }()
    
    // TODO: In future update, sort conversations newest at the top
    
    // MARK: View
    /** Overridden method called after view controller's view is loaded into memory */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        // Start the observers
        observeUserConversations()
    }
    
    
    /** Overridden method called when view controller is soon to be added to view hierarchy */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // FIXME: Find better way to check lastSeen array for the selected cell when returning
        // from ConvoViewController. Somehow must reload only that selected cell upon reentry or
        // while ConvoViewController is still being shown (use observer here)
        
        tableView.reloadData()
    }
    
    
    /** Overridden method called when view controller is soon to be removed from view hierarchy */
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Set the back button in the vc being pushed to have no text
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    
    /** Set up the look and feel of this view controller and related views */
    private func setupView() {
        
        // Set translucent navigation bar with color
        self.title = "@Me"
        self.navigationController?.navigationBar.barTintColor = Constants.Colors.primaryDark
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSForegroundColorAttributeName : UIColor.white, NSFontAttributeName: UIFont(name: "AvenirNext-Medium", size: 20)!]
        
        // Set background color appearing behind the cells
        self.tableView.backgroundColor = Constants.Colors.tableViewBackground
        self.setNeedsStatusBarAppearanceUpdate()
        
        // Establish bar button items in conversations view
        let settingsIcon = UIImage(named: "settings")
        let settingsButton = UIBarButtonItem(image: settingsIcon, style: .plain, target: self, action: #selector(didTapSettings))
        settingsButton.tintColor = UIColor.white
        
        self.navigationItem.leftBarButtonItem = settingsButton
        self.navigationItem.title = "@Me"
    }
    
    
    // MARK: Formatting
    /** 
     Format a ConversationCell (Note: Should be moved to ConversationCell.swift in future)
     - parameters:
        - cell: The ConversationCell object to be formatted
     */
    func formatConversationCell(cell: ConversationCell) {
        
        // TODO: In future update, refactor shadown code to use shadowPath (more efficient)
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
        
        // Give display picture and new message indicator a circular mask
        cell.userDisplayImageView.layer.masksToBounds = true
        cell.newMessageIndicator.layer.masksToBounds = true
        cell.userDisplayImageView.layer.cornerRadius = cell.userDisplayImageView.frame.width / 2
        cell.newMessageIndicator.layer.cornerRadius = cell.newMessageIndicator.frame.width / 2
    }
    
    
    // MARK: Observers
    /** Register this view controller to be an observer for new conversations */
    private func observeUserConversations() {
        
        let uid = UserState.currentUser.uid
        
        // Call this closure once for every conversation record, and any time a record is added
        userConversationListRef.child(uid).keepSynced(true)
        userConversationListRef.child(uid).observe(DataEventType.childAdded, with: { snapshot in
            
            let otherUsername = snapshot.key
            let message = "This is the beginning of your conversation with \(otherUsername)"
            
            if let convoID = snapshot.value as? String {
                
                // Insert a blank conversation into the data source, start observing the conversation record
                let conversation = Conversation(convoID: convoID, name: otherUsername, newestMessage: message, newestMessageTimestamp: "", unseenMessages: false)
                
                // Insert this conversation into data source and into table view
                self.insertConversation(conversation: conversation)
                
                // Start observing other properties of each conversation
                // These observers will update the corresponding conversation objects with more info asynchronously
                
                self.observeLastSeen(convoID: convoID)
                self.observeMembers(convoID: convoID)
                self.observeMessages(convoID: convoID, with: otherUsername)
            }
        })
    }
    
    
    /** 
     Register this view controller to be an observer for the most recent message of observed of a given conversation
     - parameters:
        - convoID: The conversation ID of the conversation to observe the most recent message(s) from
        - username: The username of the user with whom the conversation is with
     */
    private func observeMessages(convoID: String, with username: String) {
        
        // Retrieve a snapshot for the most recent message record in this conversation
        conversationsRef.child("\(convoID)/messages").queryLimited(toLast: 1).observe(DataEventType.childAdded, with: { snapshot in
            
            var unseenMessages = false
            var timestamp: Date = Date()
            
            if let interval = snapshot.childSnapshot(forPath: "timestamp").value as? Double {
                timestamp = Date.init(timeIntervalSince1970: interval)
                
                // If this message was sent after last time user viewed conversation, mark unseen as true
                // This will be used to set the unseen messages indicator in the conversation cell
                
                if let lastDateSeen = self.conversations[self.conversationIndexes[convoID]!].lastSeenByCurrentUser {
                    if lastDateSeen < timestamp { unseenMessages = true }
                }
            }
            
            // Extract the new message, set as the current convo's newest message!
            // If picture message, don't load, but let user know it was a picture message
            
            var message = "This is the beginning of your conversation with \(username)"
            
            if let text = snapshot.childSnapshot(forPath: "text").value as? String { message = text }
            else if let _ = snapshot.childSnapshot(forPath: "imageURL").value { message = "Picture Message" }

            
            // Go through every visible cell, determine if a cell is currently displayed for this conversation
            if let cells = self.tableView.visibleCells as? [ConversationCell] {
                for cell in cells {
                    
                    // If found, update the most recent message and efficiently move the cell to the top
                    if (cell.nameLabel.text! == username) {
                        
                        // Obtain index path where this convo is being shown as a cell
                        // We are maintaining the order of the data source (coversations), so we can safely assume that
                        // a conversaton cell at index k corresponds to conversations[k] !!
                        
                        if let currentIndexPath = self.tableView.indexPath(for: cell) {
                            self.updateRecentMessage(at: currentIndexPath.row, message: message, timestamp: timestamp, unseen: unseenMessages)
                            self.moveConversation(from: currentIndexPath, to: IndexPath(row: 0, section: 0))
                        
                        } else { print("Error: Couldn't find location of cell for convo \(convoID)") }
                    } else { print("Error: No match") }
                }
            }
        })
    }
    
    
    /** 
     Register this view controller to be an observer for the members of a given conversation
     - parameters:
        - convoID: The conversation ID of the conversation to observe the members of
     */
    private func observeMembers(convoID: String) {
        
        conversationsRef.child("\(convoID)/activeMembers/").observe(DataEventType.childAdded, with: { snapshot in
            
            let uid = snapshot.key
            
            // Extract the notification id of the user, but only add to local dictionary it that usr is not current user
            // We only need the uid or notification id for other users (eg. quick way to push notifications to all users)
            
            if let notificationID = snapshot.value as? String, let index = self.conversationIndexes[convoID] {
                if (uid != UserState.currentUser.uid) {
                    
                    // Insert uid and notification id's into sets, reload corresponding row to update cell with info
                    self.conversations[index].memberUIDs.insert(uid)
                    self.conversations[index].memberNotificationIDs.insert(notificationID)
                    self.reloadConversation(at: index)
                }
                
            } else { print("Error: Could not parse observer value for \'activeMembers\'") }
        })
    }
    
    
    /**
     Register this view controller to be an observer for the 'last seen' timestamp record
     - parameters:
        - convoID: The conversation ID of the conversation to observe the last seen timestamps
     */
    private func observeLastSeen(convoID: String) {
        
        conversationsRef.child("\(convoID)/lastSeen/\(UserState.currentUser.uid)").observe(DataEventType.value, with: { snapshot in

            // Extract the recorded timestamp of the current user's last visit to this conversation
            // This will change often, and must be updated to determine if we should display new message indicator
            
            if let interval = snapshot.value as? Double, let index = self.conversationIndexes[convoID] {

                // Store this date directly in the conversation, reload cell to update with new info
                self.conversations[index].lastSeenByCurrentUser = Date(timeIntervalSince1970: interval)
                self.reloadConversation(at: index)
            
            } else { print("Error: Could not parse observer value for \'lastSeen\'") }
        })
    }
    
    
    /**
     Update the conversations array, stored locally
     - parameters:
        - index: Index of conversation to change
        - message: The newest message in conversation
        - timestamp: The timestamp from the newest message
        - unseen: A boolean determining if conversation has been seen  ( deprecated )
     */
    func updateRecentMessage(at index: Int, message: String, timestamp: Date, unseen: Bool) {
        
        // Set properties of the conversation, specifically the ones we need to show in cell!
        conversations[index].newestMessage = message
        conversations[index].timestamp = timestamp
        conversations[index].newestMessageTimestamp = dateFormatter.string(from: timestamp)
        conversations[index].unseenMessages = unseen
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
                let selectedConvoId = conversations[indexPath.row].convoID
                
                // Using the index of selected cell, remove (hide) new message indicator from the cell!
                (tableView.cellForRow(at: indexPath) as! ConversationCell).newMessageIndicator.alpha = 0
                
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
        performSegue(withIdentifier: Constants.Segues.settingsSegue, sender: nil)
    }
}


// MARK: Empty Chat List Delegate
extension ChatListViewController: EmptyChatListDelegate {
    
    func didTapChatSomebody() {
        performSegue(withIdentifier: Constants.Segues.newConvoSegue, sender: nil)
    }
}



// MARK: Table View
extension ChatListViewController {
    
    /**
     Insert a new conversation into the data source and associated table view
     - parameters:
        - conversation: The constructed Conversation object to be inserted
     */
    func insertConversation(conversation: Conversation) {
        
        // Append conversation to data source, maintain the index lookup
        conversationIndexes[conversation.convoID] = self.conversations.count
        conversations.append(conversation)
                
        // Efficiently update by updating / inserting only the cells that need to be
        self.tableView.beginUpdates()
        self.tableView.insertRows(at: [IndexPath(row: self.conversations.count - 1, section: 0)], with: .left)
        self.tableView.endUpdates()
    }

    
    /**
     Move a conversation (data source and location in table) from an old index path to a new one. This method will
     rearrange the other elements by collapsing them to fill empty array positions
     - parameters:
        - source: The index path of the element (conversation) to be moved
        - destination: The index path to move the source element to
     */
    func moveConversation(from source: IndexPath, to destination: IndexPath) {
        
        // First update data source by removing element at source index, placing at the front
        let element = conversations.remove(at: source.row)
        conversations.insert(element, at: 0)
        
        // Update the stored indexes (map) for each conversation, now that they have been rearranged
        for (index, convo) in conversations.enumerated() {
            conversationIndexes[convo.convoID] = index
        }
        
        // TODO: In future update, iOS 11 introduces and recommends performBatchUpdates() for UITableView
        // Update the actual table view dynamically, by moving the cells
        
        self.tableView.beginUpdates()
        self.tableView.moveRow(at: source, to: destination)
        self.tableView.endUpdates()
        
        // Once cell has moved from source to destination, update the cell contents
        // This is because we changed the message for that cell earlier and didn't refresh anything
        self.tableView.reloadRows(at: [destination], with: UITableViewRowAnimation.none)
    }
    
    /**
     Reload the conversation cell located at a particular row
     - parameters:
        - row: The row to reload in the table view
     */
    func reloadConversation(at row: Int) {
        
        self.tableView.beginUpdates()
        self.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
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
        
        // A custom view should display only when no conversations can be displayed
        if (conversations.count == 0) {
            let empty = EmptyChatListView(frame: tableView.frame)
            empty.emptyChatDelegate = self
            tableView.backgroundView = empty
        
        } else {
            tableView.backgroundView = nil
        }
        
        return conversations.count
    }
    
    // ==========================================
    // ==========================================
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatListCell", for: indexPath) as! ConversationCell
        
        formatConversationCell(cell: cell)

        // Update the sender, newest message, and timestamp from this conversation
        cell.userDisplayImageView.image = UIImage(named: Constants.Assets.purpleUserImage)
        cell.nameLabel.text = conversations[indexPath.row].name
        cell.recentMessageLabel.text = conversations[indexPath.row].newestMessage
        cell.recentMessageTimeStampLabel.text = conversations[indexPath.row].newestMessageTimestamp

        // If timestamp has been read for most recent message, and we obtained most recent convo viewing,
        // we can safely update the new message indicator based on the relative time difference
        
        if let seen = conversations[indexPath.row].lastSeenByCurrentUser, let recentMessageTimestamp = conversations[indexPath.row].timestamp {
            cell.newMessageIndicator.alpha = (seen < recentMessageTimestamp) ? 1 : 0
        }
        
        // ASSUMPTION: Only two people can belong to a chat
        // Take first (only) member UID and download image for the convo cell (fail safe if not provided)
        
        if let uid = conversations[indexPath.row].memberUIDs.first {
            let path = "displayPictures/\(uid)/\(uid).JPG"
            
            databaseManager.downloadImage(into: cell.userDisplayImageView, from: path , completion: { error in
                
                if let downloadError = error {
                    print("AtMe:: An error has occurred, but image data was detected. \(downloadError)")
                    return
                }
            })
        }
        
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
        
        // Handle conversation deletion - in this app, conversations are persisted forever, but regardless,
        // the user and their convoIDs are recorded either in the active or inactive convo database records
        
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            
            // Extract conversation unique id and Firebase ref to activeMembers record
            let username = conversations[indexPath.row].name
            let convoID = conversations[indexPath.row].convoID
            
            
            // Delete conversation record from current conversations, add it to inactive conversations
            // These must be separate in database because an observer will detect all entries in active list
            
            databaseManager.leaveConversation(convoID: convoID, with: username, completion: {
                
                // Remove records from local table view data source
                self.conversations.remove(at: indexPath.row)
                
                // Delete row in tableView
                tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.right)
                tableView.reloadData()
            })
        }
    }
}
