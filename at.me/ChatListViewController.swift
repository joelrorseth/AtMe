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
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.none
        formatter.timeStyle = DateFormatter.Style.short
        
        return formatter
    }()
    
    // TODO: Sort conversations newest at the top
    
    
    
    // MARK: View
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundView = emptyView()
                
        ImageCache.default.calculateDiskCacheSize { (size) in print("Used disk size by bytes: \(size)") }
        
        setupView()
        self.setNeedsStatusBarAppearanceUpdate()
        
        // Start the observers
        observeUserConversations()
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
        self.title = "@Me"
        self.navigationController?.navigationBar.barTintColor = Constants.Colors.primaryColor
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSForegroundColorAttributeName : UIColor.white, NSFontAttributeName: UIFont(name: "AvenirNext-Medium", size: 20)!]
        
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
    private func emptyView() -> UIView {
        
        let label = UILabel(frame: CGRect(x: 30, y: tableView.bounds.size.height/3, width: tableView.bounds.size.width - 60, height: tableView.bounds.size.height/13))
        label.text = "You have no active conversations!"
        label.font = UIFont(name: "Avenir Next", size: 18)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.center
        label.heightAnchor.constraint(equalToConstant: self.tableView.frame.height / 8).isActive = true
        label.widthAnchor.constraint(equalToConstant: self.tableView.frame.width).isActive = true
        
        
        let randomButton = UIButton(type: .custom)
        randomButton.frame = CGRect(x: 30, y: tableView.bounds.size.height - (tableView.bounds.size.height/13) - 30,
                                    width: tableView.bounds.size.width - 60,
                                    height: tableView.bounds.size.height/13)
        
        randomButton.titleLabel?.font = UIFont(name: "Avenir Next Demi Bold", size: 18)
        randomButton.setTitleColor(UIColor.darkGray, for: .normal)
        randomButton.setTitleColor(UIColor.lightGray, for: .selected)
        randomButton.setTitle("Chat @Random", for: .normal)
        randomButton.titleLabel?.textAlignment = NSTextAlignment.center
        randomButton.layer.cornerRadius = Constants.Radius.regularRadius
        randomButton.backgroundColor = Constants.Colors.primaryAccent
        
        
        let background = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
        background.backgroundColor = UIColor.groupTableViewBackground
        background.addSubview(randomButton)
        background.addSubview(label)
        return background
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
        
        // Give display picture and new message indicator a circular mask
        cell.userDisplayImageView.layer.masksToBounds = true
        cell.newMessageIndicator.layer.masksToBounds = true
        cell.userDisplayImageView.layer.cornerRadius = cell.userDisplayImageView.frame.width / 2
        cell.newMessageIndicator.layer.cornerRadius = cell.newMessageIndicator.frame.width / 2
    }
    
    
    // MARK: Observers
    // ==========================================
    // ==========================================
    private func observeUserConversations() {
        
        let uid = UserState.currentUser.uid
        
        // Call this closure once for every conversation record, and any time a record is added
        userConversationListRef.child(uid).keepSynced(true)
        userConversationListRef.child(uid).observe(DataEventType.childAdded, with: { snapshot in
            
            let otherUsername = snapshot.key
            let message = "This is the beginning of your conversation with \(otherUsername)"
            
            if let convoID = snapshot.value as? String {
                
                // Insert a blank conversation into the data source, start observing the conversation record
                let conversation = Conversation(convoID: convoID, name: otherUsername, newestMessage: message, newestMessageTimestamp: "")
                self.conversations.append(conversation)
                
                self.insertConversationCell(conversation: conversation)
                self.observeConversation(convoId: convoID, with: otherUsername)
            }
        })
    }
    
    
    // ==========================================
    // ==========================================
    private func observeConversation(convoId: String, with username: String) {
        
        // Retrieve a snapshot for the most recent message record in this conversation
        conversationsRef.child("\(convoId)/messages").queryLimited(toLast: 1).observe(DataEventType.childAdded, with: { snapshot in
            
            var messageTimestamp: String = ""
            
            if let interval = snapshot.childSnapshot(forPath: "timestamp").value as? Double {
                let timestamp = Date.init(timeIntervalSince1970: interval)
                messageTimestamp = self.dateFormatter.string(from: timestamp)
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
                            self.updateRecentMessage(at: currentIndexPath.row, message: message, timestamp: messageTimestamp)
                            self.moveConversation(from: currentIndexPath, to: IndexPath(row: 0, section: 0))
                        
                        } else { print("Error: Couldn't find location of cell for convo \(convoId)") }
                    } else { print("Error: No match") }
                }
            }
        })
    }
    
    
    // ==========================================
    // ==========================================
    func updateRecentMessage(at index: Int, message: String, timestamp: String) {
        
        conversations[index].newestMessage = message
        conversations[index].newestMessageTimestamp = timestamp
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
        
        
        // Efficiently update by updating / inserting only the cells that need to be
        self.tableView.beginUpdates()
        self.tableView.insertRows(at: [IndexPath(row: self.conversations.count - 1, section: 0)], with: .left)
        self.tableView.endUpdates()
    }
    
    // ==========================================
    // ==========================================
    func moveConversation(from source: IndexPath, to destination: IndexPath) {
        
        // First update data source by removing element at source index, placing at the front
        let element = conversations.remove(at: source.row)
        conversations.insert(element, at: 0)
        
        // TODO: In future update, iOS 11 introduces and recommends performBatchUpdates() for UITableView
        // Update the actual table view dynamically, by moving the cells
        
        self.tableView.beginUpdates()
        self.tableView.moveRow(at: source, to: destination)
        self.tableView.endUpdates()
        
        // Once cell has moved from source to destination, update the cell contents
        // This is because we changed the message for that cell earlier and didn't refresh anything
        self.tableView.reloadRows(at: [destination], with: UITableViewRowAnimation.automatic)
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
        print("CellForRow() found message \"\(conversations[indexPath.row].newestMessage) at \(indexPath.row)")
        // Update the sender, newest message, and timestamp from this conversation
        cell.nameLabel.text = conversations[indexPath.row].name
        cell.recentMessageLabel.text = conversations[indexPath.row].newestMessage
        cell.recentMessageTimeStampLabel.text = conversations[indexPath.row].newestMessageTimestamp
        
        
        // TODO: Refactor Conversation class to hold the uid of the other user
        // This way, don't need to lookup uid and can access storage reference right away
        
        rootDatabaseRef.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            
            if let uid = snapshot.childSnapshot(forPath: "registeredUsernames/\(self.conversations[indexPath.row].name)").value as? String {
                if let _ = snapshot.childSnapshot(forPath: "userInformation/\(uid)/displayPicture").value as? String {
                    
                    DatabaseController.downloadImage(into: cell.userDisplayImageView, from: self.userDisplayPictureRef.child("\(uid)/\(uid).JPG") , completion: { (error) in
                        
                        if let downloadError = error {
                            print("At.ME:: An error has occurred, but image data was detected. \(downloadError)")
                            return
                        }
                        
                        //print("At.ME:: Image data was downloded and converted successfully")
                        
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
            
            userConversationListRef.child(UserState.currentUser.uid).child(conversations[indexPath.row].name).removeValue()
            
            // Extract conversation unique id and Firebase ref to activeMembers record
            let convoId = conversations[indexPath.row].convoID
            let activeMembersRef = conversationsRef.child("\(convoId)/activeMembers")
            
            
            activeMembersRef.observeSingleEvent(of: .value, with: { snapshot in
                
                // Remove current user from members list in database
                // If current user was the last member, the conversation will delete entirely
                
                var members = snapshot.value as? [String: String]
                members?.removeValue(forKey: UserState.currentUser.uid)
                
                if (members?.count == 0) {
                    self.conversationsRef.child(convoId).removeValue()
                } else {
                    activeMembersRef.setValue(members)
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
