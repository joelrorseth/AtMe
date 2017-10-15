//
//  ChatListViewController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-02-18.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase

class ChatListViewController: UITableViewController {
    
    lazy var databaseManager = DatabaseController()
    lazy var authManager = AuthController()
    
    // Firebase references are used for read/write at referenced location
    lazy var userConversationListRef: DatabaseReference = Database.database().reference().child("userConversationList")
    lazy var userInactiveConversationsRef: DatabaseReference = Database.database().reference().child("userInactiveConversations")
    lazy var conversationsRef: DatabaseReference = Database.database().reference().child("conversations")
        
    // Local conversation data source
    var conversations: [Conversation] = []
    var conversationIndexes: [String : Int] = [:]
    var currentlySelectedIndexPath: IndexPath?
    
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.none
        formatter.timeStyle = DateFormatter.Style.short
        
        return formatter
    }()
    
    
    // MARK: - View
    /** Overridden method called after view controller's view is loaded into memory */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        authManager.authenticationDelegate = self
        
        // Start the observers
        observeUserConversations()
    }
    
    
    /** Overridden method called when view controller will been removed from view hierarchy. */
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Set the back button in the vc being pushed to have no text
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // If this view controller is being popped off navigation stack, then remove all observers
        // TODO: Find a way to call removeObservers() when user signs out (unwind segue is skipping this in Settings)
        if self.isMovingFromParentViewController { removeAllObservers() }
    }
    
    
    /** Set up the look and feel of this view controller and related views. */
    private func setupView() {
        
        // Set translucent navigation bar with color
        self.title = "@Me"
        self.navigationController?.navigationBar.barTintColor = Constants.Colors.primaryDark
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSAttributedStringKey.foregroundColor : UIColor.white, NSAttributedStringKey.font: UIFont(name: "AvenirNext-Medium", size: 20)!]
        
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
    
    
    // MARK: - Observers
    /** Register this view controller to be an observer for new conversations */
    private func observeUserConversations() {
        
        let uid = UserState.currentUser.uid
        
        // Call this closure once for every conversation record, and any time a record is added
        userConversationListRef.child(uid).keepSynced(true)
        
        
        // Observe all conversations and any added afterwards
        userConversationListRef.child(uid).observe(DataEventType.childAdded, with: { snapshot in
            
            let otherUsername = snapshot.key
            let message = "This is the beginning of your conversation with \(otherUsername)"
            
            if let convoID = snapshot.value as? String {
                
                // Insert a blank conversation into the data source, start observing the conversation record
                let conversation = Conversation(convoID: convoID, name: otherUsername, newestMessage: message, timestamp: Date(), newestMessageTimestamp: "", unseenMessages: false)
                
                // Insert this conversation into data source and into table view
                self.insertConversation(conversation: conversation)
                
                // Start observing other properties of each conversation
                // These observers will update the corresponding conversation objects with more info asynchronously
                
                self.observeLastSeen(convoID: convoID)
                self.observeMembers(convoID: convoID)
                self.observeMessages(convoID: convoID, with: otherUsername)
            }
        })
        
        
        // Observe all removals of conversations from the active conversation list in database
        userConversationListRef.child(uid).observe(DataEventType.childRemoved, with: { snapshot in
            
            if let convoID = snapshot.value as? String {
                print("Observed convo removal for \(convoID)")
                self.removeConversation(convoID: convoID)
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
            
            // Check if conversation still exists locally, prevent going any further if not
            guard let convoIndex = self.conversationIndexes[convoID] else {
                print("Error: Received a message, but its conversation no longer exists.")
                return
            }
            
            var unseenMessages = false
            var timestamp: Date = Date()
            
            if let interval = snapshot.childSnapshot(forPath: "timestamp").value as? Double {
                timestamp = Date.init(timeIntervalSince1970: interval)
                
                // If this message was sent after last time user viewed conversation, mark unseen as true
                // This will be used to set the unseen messages indicator in the conversation cell
                
                if let lastDateSeen = self.conversations[convoIndex].lastSeenByCurrentUser {
                    if lastDateSeen < timestamp { unseenMessages = true }
                }
            }
            
            // Extract the new message, set as the current convo's newest message!
            // If picture message, don't load, but let user know it was a picture message
            
            var message = "This is the beginning of your conversation with \(username)"
            
            if let text = snapshot.childSnapshot(forPath: "text").value as? String { message = text }
            else if let _ = snapshot.childSnapshot(forPath: "imageURL").value { message = Constants.Placeholders.pictureMessagePlaceholder }

        
            // Actually update the conversation cell with this new information
            self.updateMostRecentMessageAt(indexPath: IndexPath(row: convoIndex, section: 0) , to: message, timestamp: timestamp, unseen: unseenMessages)
        })
    }
    
    
    /** 
     Register this view controller to be an observer for active and inactive members of a given conversation
     - parameters:
        - convoID: The conversation ID of the conversation to observe the members of
     */
    private func observeMembers(convoID: String) {
        
        // Observe active members
        conversationsRef.child("\(convoID)/activeMembers/").observe(DataEventType.childAdded, with: { snapshot in
            
            // Each child will be a (uid: username pair)
            let uid = snapshot.key
            
            // Add the active member's uid to the set, update the convo image
            // Important: Don't add current user (we assume throughout app that we don't track current user)
            if let row = self.conversationIndexes[convoID] {
                if (uid != UserState.currentUser.uid) {
                    
                    self.conversations[row].activeMemberUIDs.insert(uid)
                    self.updateConversationImageAt(indexPath: IndexPath(row: row, section: 0))
                }
            } else { print("Error: Could not parse active member or no conversation was found for member") }
        })
        
        

        // Observe inactive members so we can still obtain profile pic for convo
        conversationsRef.child("\(convoID)/inactiveMembers/").observe(DataEventType.childAdded, with: { snapshot in
            
            let uid = snapshot.key
            
            // Add the inactive member's uid to the set, update convo image
            if let row = self.conversationIndexes[convoID] {
                if (uid != UserState.currentUser.uid) {
                    
                    self.conversations[row].inactiveMemberUIDs.insert(uid)
                    self.updateConversationImageAt(indexPath: IndexPath(row: row, section: 0))
                }
            } else { print("Error: Could not parse active member or no conversation was found for member") }
        })
    }
    
    
    
    /**
     Register this view controller to be an observer for the 'last seen' timestamp record. This will keep the new message indicator 
     in sync with what has been written to the database, and always updates as long as this view controller is in the nav stack.
     - parameters:
        - convoID: The conversation ID of the conversation to observe the last seen timestamps
     */
    private func observeLastSeen(convoID: String) {
        
        conversationsRef.child("\(convoID)/lastSeen/\(UserState.currentUser.uid)").observe(DataEventType.value, with: { snapshot in

            // Extract the recorded timestamp of the current user's last visit to this conversation
            // This will change often, and must be updated to determine if we should display new message indicator
            
            if let interval = snapshot.value as? Double, let row = self.conversationIndexes[convoID] {

                // Update only the new message indicator
                self.updateUnseenMessageStatusAt(indexPath: IndexPath(row: row, section: 0), using: Date(timeIntervalSince1970: interval))
            
            } else { print("Error: Could not parse observer value for \'lastSeen\'") }
        })
    }
    
    
    /** Removes all database observers active in this view controller. */
    internal func removeAllObservers() {
        
        userConversationListRef.child(UserState.currentUser.uid).keepSynced(false)
        conversationsRef.keepSynced(false)
        userConversationListRef.removeAllObservers()
        conversationsRef.removeAllObservers()
        
        print("Removing chat list observers")
        for convo in conversations {
            
            // Remove all observers set up during lifetime
            // TODO: Removing messages / user conversations observers seems to not be working
            // However, Firebase states: Listener at <path> failed: permission_denied (probably okay?)
            
            userConversationListRef.child("\(UserState.currentUser.uid)/").removeAllObservers()
            conversationsRef.child(convo.convoID).child("messages").removeAllObservers()
            
            conversationsRef.child("\(convo.convoID)/activeMembers/").removeAllObservers()
            conversationsRef.child("\(convo.convoID)/lastSeen/\(UserState.currentUser.uid)").removeAllObservers()
        }
    }
    
    
    // MARK: - Segue
    /** Overridden method providing an opportunity for data transfer to destination view controller before segueing to it. */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == Constants.Segues.loadConvoSegue) {
            let cvc = segue.destination as! ConvoViewController
            
            
            // Get the index path of selected row that triggered segue
            // The rows correspond directly with ordering in table view
            // Pass along convoId of selected conversation
            
            if let indexPath = tableView.indexPathForSelectedRow {
                
                let selectedConvoId = conversations[indexPath.row].convoID
                cvc.convoId = selectedConvoId
                
                // Pass the actual conversation object
                //cvc.conversation = conversations[indexPath.row]
                cvc.messagesRef = conversationsRef.child("\(selectedConvoId)/messages")
                cvc.navigationItem.title = conversations[indexPath.row].name
                
                // Important: Pass most recent message so that next view controller knows when it
                // should scroll to bottom (instead of doing it for every message!)
                cvc.mostRecentMessageTimestamp = conversations[indexPath.row].timestamp
                
                // Track selected index for return to this view controller
                currentlySelectedIndexPath = indexPath
                
                // Using the index of selected cell, remove (hide) new message indicator from the cell!
                (tableView.cellForRow(at: indexPath) as! ConversationCell).newMessageIndicator.alpha = 0
            }
        }
    }
    
    
    /** Method stub for unwind segue to this view controller from another. */
    @IBAction func unwindToChatList(segue: UIStoryboardSegue) {}
    
    
    // MARK: Functionality
    /** Selector method used in the event that the settings icon is tapped. */
    @objc private func didTapSettings() {
        performSegue(withIdentifier: Constants.Segues.settingsSegue, sender: nil)
    }
}



// MARK: - Empty Chat List Delegate
extension ChatListViewController: EmptyChatListDelegate {
    
    /** Delegate method implementation which fires when user selects '@Somebody' in an EmptyChatListView */
    func didTapChatSomebody() {
        performSegue(withIdentifier: Constants.Segues.newConvoSegue, sender: nil)
    }
}



// MARK: - AuthenticationDelegate
extension ChatListViewController: AuthenticationDelegate {
    
    /** Handles the AuthenticationDelegate function called when the current user signs out */
    func userDidSignOut() {
        
        // Upon sign out, we need to remove all observers in this view controller
        // This has to be done using delegate, because unwind segue from Settings skips code in this controller
        removeAllObservers()
    }
}



// MARK: - Data source efficient manipulation
extension ChatListViewController {
    
    
    /** Refresh the data source by sorting it and updating the associated index lookup array. */
    func refreshDataSourceOrdering() {
        
        // Sort data source
        conversations.sort(by: { $0.timestamp > $1.timestamp })
        
        // Update corresponding indexes with new sorted positions
        for (index, convo) in conversations.enumerated() {
            conversationIndexes[convo.convoID] = index
        }
    }
    
    
    /**
     Insert a new conversation into the data source and ask table view to update accordingly.
     - parameters:
        - conversation: The constructed Conversation object to be inserted
     */
    func insertConversation(conversation: Conversation) {
        
        // Add conversation to data source, then refresh it (sort and update indicies)
        conversations.append(conversation)
        refreshDataSourceOrdering()
        
        // Using refreshed index lookup, animate the insert at new position
        if let newIndex = conversationIndexes[conversation.convoID] {
            animateConversationInsert(at: IndexPath(row: newIndex, section: 0))
        }
    }
    
    
    /** Remove conversation from the data source and ask table view to update accordingly.
     - parameters:
        - convoID: The conversation ID of the conversation to be deleted
     */
    func removeConversation(convoID: String) {
        
        guard let row = conversationIndexes[convoID] else { return }
        let indexPath = IndexPath(row: row, section: 0)
        
        conversations.remove(at: row)
        conversationIndexes.removeValue(forKey: convoID)
        
        // Refresh the data source (indexes and actual conversations)
        // Cell can be animated off screen now because data source matches
        refreshDataSourceOrdering()
            
        print("Removed convo at array/table row \(row)")
        animateConversationRemoval(at: indexPath)
    }
    
    
    /** Update the data source and cell located at an IndexPath with provided information.
     This avoids reloading entire cell if it does not require moving indexes in table (eg. move to top b/c new).
     - parameters:
        - indexPath: The IndexPath where the update is occuring.
        - message: The new, updated message to display.
        - timestamp: The Date timestamp for new message.
        - unseen: A Bool which is true if the conversation now has unseen messages.
     */
    func updateMostRecentMessageAt(indexPath: IndexPath, to message: String, timestamp: Date, unseen: Bool) {
        
        // Set properties of the conversation, specifically the ones we need to show in cell!
        conversations[indexPath.row].newestMessage = message
        conversations[indexPath.row].timestamp = timestamp
        conversations[indexPath.row].newestMessageTimestamp = dateFormatter.string(from: timestamp)
        conversations[indexPath.row].unseenMessages = unseen
        
        let convoIDBeingEdited = conversations[indexPath.row].convoID
        
        
        // Update the contents of the cell immediately without calling cellForRow()
        if let cell = tableView.cellForRow(at: indexPath) as? ConversationCell {
            cell.recentMessageLabel.text = message
            cell.recentMessageTimeStampLabel.text = dateFormatter.string(from: timestamp)
            
            // Unwrap and determine if message being updated has been seen by current user
            if let conversationLastSeen = conversations[indexPath.row].lastSeenByCurrentUser {
                cell.newMessageIndicator.alpha = (conversationLastSeen < timestamp) ? 1 : 0
            }
        }
        
        // Since only one element is ever inserted at a time, we know only one move should be doneto rearrange table view
        // This is because we can move table view cells using UIKit and other cells will shift to match data source
        refreshDataSourceOrdering()
        
        
        // Using refreshed index lookup, animate the move from the old position (indexPath.row) to new position
        if let newIndex = conversationIndexes[convoIDBeingEdited] {
            if (indexPath.row != newIndex) {
                animateConversationMove(from: indexPath, to: IndexPath(row: newIndex, section: 0))
            }
        }
    }
    
    
    /** Update the new message status and corresponding indicator in data source and cell located at an IndexPath.
     This avoids reloading entire cell if it does not require moving indexes in table (eg. move to top b/c new).
     - parameters:
     - indexPath: The IndexPath where the update is occuring.
     - date: The new Date object being used as the new most recent 'seen' timestamp.
     */
    func updateUnseenMessageStatusAt(indexPath: IndexPath, using date: Date) {
        
        // Store this date directly in the conversation, reload cell to update with new info
        conversations[indexPath.row].lastSeenByCurrentUser = date
        
        // Change only the new message indicator instead of reloading cell / cellForRowAt()
        // Unwrap and determine if new timestamp requres display/hide the new message indicator
        
        if let cell = tableView.cellForRow(at: indexPath) as? ConversationCell, let timestamp = conversations[indexPath.row].timestamp {
            cell.newMessageIndicator.alpha = (date < timestamp) ? 1 : 0
        }
    }
    
    
    /** 
     Update the conversation image view (only) of a cell located at a specified IndexPath.
     This avoids reloading entire cell if it does not require moving indexes in table (eg. move to top b/c new).
     - parameters:
        - indexPath: The IndexPath where the update is occuring.
     */
    func updateConversationImageAt(indexPath: IndexPath) {
        
        // Extract the relevant user, either from active or inactive member list (it should be in one or the other)
        // Even if user has left convo, we still need their display picture to show
        
        guard let uid = conversations[indexPath.row].activeMemberUIDs.first ?? conversations[indexPath.row].inactiveMemberUIDs.first else {
            print("Attempted to update convo image at \(indexPath), but uid for display pic wasn't found at all.")
            return
        }
        
        
        // Download the image of the user with 'uid; and load it into the conversation cell
        if let cell = tableView.cellForRow(at: indexPath) as? ConversationCell {
            let path = "displayPictures/\(uid)/\(uid).JPG"
            
            databaseManager.downloadImage(into: cell.userDisplayImageView, from: path , completion: { error in
                
                if let downloadError = error {
                    print("AtMe:: An error has occurred, but image data was detected. \(downloadError)")
                    return
                }
            })
        }
    }
}



// MARK: Table View
extension ChatListViewController {
    
    
    /** Animate the insertion of a cell at the specified row. 
     - parameters:
        - destination: The IndexPath to insert the new row at.
     */
    func animateConversationInsert(at destination: IndexPath) {
        self.tableView.insertRows(at: [destination], with: .automatic)
    }
    
    
    /** Animate the removal of a cell at the specified row.
     - parameters:
        - indexPath: IndexPath of cell to be removed
    */
    func animateConversationRemoval(at indexPath: IndexPath) {
        self.tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    
    /**
     Animate the table view cell located at *source* to the new index path defined by *destination*.
     - parameters:
        - source: The index path of the element (conversation) to be moved
        - destination: The index path to move the source element to
     */
    func animateConversationMove(from source: IndexPath, to destination: IndexPath) {
        self.tableView.moveRow(at: source, to: destination)
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
    
    
    /** Sets the number of sections to display in the table view. */
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    /** Determines the height of the table view cell at specified index path. */
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(94)
    }
    
    
    /** Sets the number of rows to render for a given section in the table view. */
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // A custom view should display only when no conversations can be displayed
        if (conversations.count == 0) {
            let empty = EmptyChatListView(frame: tableView.frame)
            empty.emptyChatDelegate = self
            tableView.backgroundView = empty
        
        } else { tableView.backgroundView = nil }
        
        return conversations.count
    }
    
    
    /** Determines the content of the table view cell at specified index path. */
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
        
        updateConversationImageAt(indexPath: indexPath)
        
        return cell
    }
    
    
    /** Determines if the user can edit the table view. */
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    /** Determines course of action to take when user edits the table view, depending on the type of edit being requested. */
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
                // At this point, childRemoved observer will take care of table view removal and
                // data source. This allows the database to keep in sync at its own pace.
            })
        }
    }
}
