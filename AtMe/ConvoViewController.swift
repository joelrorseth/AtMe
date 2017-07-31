//
//  ConvoViewController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-02-18.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase


class ConvoViewController: UITableViewController, AlertController {
    
    
    // MARK: - Properties
    // Firebase references
    var conversationRef: DatabaseReference?
    var messagesRef: DatabaseReference? = nil
    
    var messagesHandle: DatabaseHandle?
    var activeMembersHandle: DatabaseHandle?
    
    var observingMessages = false
    var messages: [Message] = []
    var notificationIDs: [String] = []
    var currentMessageCountLimit = Constants.Limits.messageCountStandardLimit
    
    // FIXME: This needs to be refactored, along with prepareForSegue in ChatList
    var convoId: String = "" {
        didSet {
            conversationRef = Database.database().reference().child("conversations/\(convoId)")
            messagesRef = Database.database().reference().child("conversations/\(convoId)/messages/")
            observeNotificationIDs()
            if (!observingMessages) { observeReceivedMessages(count: currentMessageCountLimit); observingMessages = true }
        }
    }
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.none
        formatter.timeStyle = DateFormatter.Style.short
        
        return formatter
    }()
    
    
    
    // MARK: - Input Accessory View
    fileprivate let chatToolbarView: ChatToolbarView = {
        let view = ChatToolbarView(frame: CGRect.zero, inputViewStyle: UIInputViewStyle.default)
        
        // Add selectors as targets to the toolbar buttons
        view.sendButton.addTarget(self, action: #selector(didPressSend(sender:)), for: UIControlEvents.touchUpInside)
        view.libraryButton.addTarget(self, action: #selector(didPressLibraryIcon(sender:)), for: UIControlEvents.touchUpInside)
        view.cameraButton.addTarget(self, action: #selector(didPressCameraIcon(sender:)), for: UIControlEvents.touchUpInside)
        
        return view
    }()
    
    
    /** Provide the view controller's inputAccessoryView object. */
    override var inputAccessoryView: UIView? { return chatToolbarView }
    
    
    /** Give the view controller permission to become first responder. */
    override var canBecomeFirstResponder: Bool { return true }
    
    
    /** Convenience method to dismiss the input accessory (toolbar). */
    func dismissKeyboard() {
        
        // Dismiss toolbar and keyboard only if required
        if chatToolbarView.expandingTextView.isFirstResponder {
            chatToolbarView.expandingTextView.resignFirstResponder()
            self.scrollToNewestMessage()
        }
    }
    
    
    // MARK: Button methods
    /** Action method which fires when the user taps 'Send'. */
    @objc func didPressSend(sender: Any) {
        
        if (chatToolbarView.expandingTextView.text == "" || chatToolbarView.expandingTextView.text == nil ||
            chatToolbarView.expandingTextView.text == Constants.Placeholders.messagePlaceholder) { return }
        
        // Extract message then reset keyboard and toolbar
        let message = Message(
            imageURL: nil,
            sender: UserState.currentUser.username,
            text: chatToolbarView.expandingTextView.text!,
            timestamp: Date()
        )
        
        // Pass message along to be stored
        send(message: message)
        
        dismissKeyboard()
        chatToolbarView.reset()
    }
    
    
    /** Action method which fires when user taps the image library icon. */
    @objc func didPressLibraryIcon(sender: Any) {
     
        dismissKeyboard()

        // Create photo library image picker and present
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        
        DispatchQueue.main.async {
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    
    /** Action method which fires when the user taps the camera icon. */
    @objc func didPressCameraIcon(sender: Any) {
        
        dismissKeyboard()
        
        // Create camera image picker and present
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = UIImagePickerControllerSourceType.camera
        
        DispatchQueue.main.async {
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    
    
    // MARK: - View
    /** Overridden method called after view controller's view is loaded into memory. */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set table view properties
        tableView.backgroundColor = UIColor.groupTableViewBackground
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .interactive
        
        // Set the delegate of the text view inside the chat toolbar
        // We will handle changes in this view controller
        
        chatToolbarView.expandingTextView.delegate = self

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadWithMoreMessages), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl
        
        addGestureRecognizers()
    }
    
    
    /** Overridden method called when view controller will been removed from view hierarchy. */
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // If this view controller is being popped off navigation stack, then remove all observers
        if self.isMovingFromParentViewController { removeAllObservers() }
    }
    
    
    
    // MARK: - Managing messages
    /** Perform required actions to send a given Message. */
    func send(message: Message) {
        
        // Write the message to Firebase
        let randomMessageId = messagesRef!.childByAutoId().key
        
        // Each message record (uniquely identified) will record sender and message text
        if let text = message.text {
            messagesRef?.child(randomMessageId).setValue(
                ["sender" : message.sender, "text" : text, "timestamp" : message.timestamp.timeIntervalSince1970]
            )
            
        } else if let imageURL = message.imageURL {
            messagesRef?.child(randomMessageId).setValue(
                ["imageURL": imageURL, "sender" : message.sender, "timestamp" : message.timestamp.timeIntervalSince1970]
            )
        }
        
        
        // Set timestamp for most recent conversation viewing
        // This is required to later determine if messages loaded have already been seen
        updateLastSeenTimestamp(convoID: convoId)
        
        // Ask NotificationController to send this message as a push notification
        for notificationID in notificationIDs {
            NotificationsController.send(to: notificationID, title: message.sender, message: message.text ?? "Picture message")
        }
    }
    
    
    /** Adds a given Message to the table view (chat) by inserting only what it needs to. */
    private func addMessage(message: Message) {
        
        // Efficiently update by updating / inserting only the cells that need to be
        DispatchQueue.main.async {
            
            // Update data source then scroll to new messgae
            // Apparently, this must be done in this same main thread to prevent race condition
            
            self.messages.append(message)
            self.tableView.insertRows(at: [IndexPath(row: self.messages.count - 1, section: 0)], with: .none)
            self.scrollToNewestMessage()
        }
    }
    
    
    // TODO: In future update, refactor into DatabaseController
    /** Update the current user's 'last seen timestamp' for a given conversation in the database. */
    private func updateLastSeenTimestamp(convoID: String) {
        
        conversationRef?.child("lastSeen/\(UserState.currentUser.uid)").setValue(Date().timeIntervalSince1970)
    }
    
    
    
    // MARK: - Observers
    /**
     Observe the messages of the current conversation. Initially, a given number of messages will be
     observed, along with each newly added value afterwards.
     - parameters:
     - count: The number of most recent messages to load when the method is first called
     */
    private func observeReceivedMessages(count: Int) {
        
        let messagesQuery = messagesRef?.queryLimited(toLast: UInt(count))
        messagesQuery?.keepSynced(true)
        
        // This closure is triggered once for every existing record found, and for each record added here
        messagesHandle = messagesQuery?.observe(DataEventType.childAdded, with: { snapshot in
            
            var imageURL: String?
            var text: String?
            
            // Unwrap picture message url or text message, can and must always be only one or the other
            if let imageURLValue = snapshot.childSnapshot(forPath: "imageURL").value as? String { imageURL = imageURLValue }
            if let textValue = snapshot.childSnapshot(forPath: "text").value as? String { text = textValue }
            
            let sender = snapshot.childSnapshot(forPath: "sender").value as! String
            let timestamp = Date.init(timeIntervalSince1970: snapshot.childSnapshot(forPath: "timestamp").value as! Double)
            
            // Because a new message has arrived, update the last message seen timestamp!
            self.updateLastSeenTimestamp(convoID: self.convoId)
            
            // Add message to local messages cache
            self.addMessage(message: Message(imageURL: imageURL, sender: sender, text: text, timestamp: timestamp))
        })
    }
    
    
    /**
     Observe all existing and new notification IDs for the current conversation.
     Instead of observing them directly, we observe existing and new members, then retrieve their latest stored notification id
     */
    private func observeNotificationIDs() {
        
        activeMembersHandle = conversationRef?.child("activeMembers").observe(DataEventType.childAdded, with: { snapshot in
            
            // Each member in activeMembers stores key-value pairs, specifically  (uid: username) for all *active* users
            // Firebase will take snapshot of each existing and new notificationID, store in property for push notifications later
            
            let uid = snapshot.key
            if (uid == UserState.currentUser.uid) { return }
            
            // Ask database manager for the *current* notification ID of every observed member
            DatabaseController.notificationIDForUser(with: uid, completion: { notificationID in
                
                if let id = notificationID {
                    
                    // Add to local copy, but write it back to database as well
                    self.notificationIDs.append(id)
                }
            })
        })
    }
    
    
    /** Removes all database observers active in this view controller. */
    private func removeAllObservers() {
        
        //messagesRef?.keepSynced(false)
        
        if let ref = messagesRef, let handle = messagesHandle {
            ref.removeObserver(withHandle: handle)
        }
        
        if let ref = conversationRef, let handle = activeMembersHandle {
            ref.removeObserver(withHandle: handle)
        }
    }
    
    
    /**
     Reload this conversation entirely, this time loading in a larger number of recent messages.
     The current implementation scraps the message observer, and adds a new one querying more messages initially.
     */
    @objc private func reloadWithMoreMessages() {
        
        // Remove the messages observer to start over and query a larger amount
        if let ref = messagesRef {
            ref.removeAllObservers()
            
            // Remove data from data source
            messages.removeAll()
            tableView.reloadData()
            
            // Increase number of messages to load by a constant factor
            currentMessageCountLimit += Constants.Limits.messageCountIncreaseLimit
            observeReceivedMessages(count: currentMessageCountLimit)
            
        } else { print("Error: Could not unwrap handle or database ref to start the reload") }
        
        // Stop the reloading animation
        tableView.refreshControl?.endRefreshing()
    }
    
    
    // MARK: - Gesture Recognizers
    /** Add gesture recognizer to track dismiss keyboard area */
    private func addGestureRecognizers() {
        
        // Add gesture recognizer to handle tapping outside of keyboard
        let dismissKeyboardTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.tableView.addGestureRecognizer(dismissKeyboardTap)
    }
    
    
    // MARK: - Additional functions
    /**
     Obtains a timestamp of the current moment in time (described as the interval from 1970 until now)
     - returns: A TimeInterval object representing the time interval since 1970
     */
    func getCurrentTimestamp() -> TimeInterval {
        return Date().timeIntervalSince1970
    }
}


// MARK: - UIImagePickerControllerDelegate
extension ConvoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // TODO: In future update, refactor
    /** Called when media has been selected by the user in the image picker. */
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // Immediately dismiss image picker to keep the UI responsive
        if convoId == "" { return }
        self.dismiss(animated: true)
        
        let path = "conversations/\(convoId)/images/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
        
        // Extract the image after editing, upload to database as Data object
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            if let data = convertImageToData(image: image) {
                
                DatabaseController.uploadImage(data: data, to: path, completion: { (error) in
                    if let error = error {
                        print("AtMe:: Error uploading picture message to Firebase. \(error.localizedDescription)")
                        return
                    }
                    
                    // Now that image has uploaded, officially send the message record to the database with storage URL
                    let message = Message(imageURL: path, sender: UserState.currentUser.username, text: nil, timestamp: Date())
                    self.send(message: message)
                })
                
            } else { print("AtMe:: Error extracting image from source") }
        } else { print("AtMe:: Error extracting edited UIImage from info dictionary") }
    }
    
    
    /** Called if and when the user has cancelled the image picking operation. */
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}



// MARK: - UITextViewDelegate
extension ConvoViewController: UITextViewDelegate {
    
    /** Delegate method which fires when the specified text view has begun editing. */
    func textViewDidBeginEditing(_ textView: UITextView) {
        //print("Text field began editing")
        
        // Change to active text colour
        chatToolbarView.expandingTextView.textColor = UIColor.darkGray
        
        if (chatToolbarView.expandingTextView.text == Constants.Placeholders.messagePlaceholder) {
            chatToolbarView.expandingTextView.text = ""
        }
        
        
        // If the message has default text (hasn't been touched), then commit to text based message now
        // TODO: Fix auto layout glitch where text would scroll instead of resize
        // TODO: In future, dismiss buttons only when text has actually been entered
        
//        if (chatToolbarView.expandingTextView.text == Constants.Placeholders.messagePlaceholder) {
//            chatToolbarView.commitToTextBasedMessage()
//        }
        
        scrollToNewestMessage()
    }
    
    
    /** Delegate method which fires when the specified text view has ended editing. */
    func textViewDidEndEditing(_ textView: UITextView) {
        //print("Text field ended editing")
        
        self.chatToolbarView.expandingTextView.textColor = UIColor.gray
        
        if (chatToolbarView.expandingTextView.text == "") {
            chatToolbarView.expandingTextView.text = Constants.Placeholders.messagePlaceholder
        }
        
        // TODO: Reimplement these checks in a regular fashion
        // If the text is back to nothing, now reallow picture to be selected using toolbar
        
//        if (chatToolbarView.expandingTextView.text == "") {
//            chatToolbarView.uncommitToTextBasedMessage()
//        }
    }
}



// MARK: - Table View Delegate
extension ConvoViewController {
    
    
    /** Scroll to current bottom row of the table view. */
    func scrollToNewestMessage() {
        if messages.count > 0 {
            tableView.scrollToRow(at: IndexPath.init(row: messages.count - 1, section: 0) , at: .bottom, animated: true)
        }
    }
    
    /** Sets the number of sections to display in the table view. */
    override func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    
    
    /** Sets the number of rows to render for a given section in the table view. */
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return messages.count }
    
    
    /** Determines the height of the table view cell at specified index path. */
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if let text = messages[indexPath.row].text {
            return sizeForString(text, maxWidth: tableView.bounds.width * 0.7, font: Constants.Fonts.regularText).height + (2 * MessageCell.verticalBubbleSpacing) + (2 * MessageCell.verticalInsetPadding)
        }
        
        if let _ = messages[indexPath.row].imageURL {
            return 200 + (2 * MessageCell.verticalBubbleSpacing) + (2 * MessageCell.verticalInsetPadding)
        }
        
        return 0
    }
    
    
    /** Determines the content of the table view cell at specified index path. */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // TODO: In the future, this cell configuration code should take place in the MessageCell
        // class. However, only so much can be done there since initializer will not know if message
        // is sent or received
        
        // Dequeue a custom cell for collection view
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Storyboard.messageId, for: indexPath) as! MessageCell
        let message = messages[indexPath.row]
        
        // Clear message fields
        cell.messageImageView.image = nil
        cell.messageTextView.text = ""
        
        var messageSize = CGSize(width: 0, height: 0)
        var messageContentReference: UIView? = nil
        
        // Normal Text Message
        if let text = message.text {
            messageSize = sizeForString(text, maxWidth: tableView.bounds.width * 0.7, font: Constants.Fonts.regularText)
            messageContentReference = cell.messageTextView
            
            cell.messageTextView.text = message.text
        }
        
        // Picture Message
        if let imageURL = message.imageURL {
            
            messageSize = CGSize(width: Constants.Sizes.pictureMessageDefaultWidth, height: Constants.Sizes.pictureMessageDefaultHeight)
            messageContentReference = cell.messageImageView
            
            // To fix weird bug where images would not remove from reused cells, we manually add and remove image view from cells
            cell.addImageView()
            DatabaseController.downloadImage(into: cell.messageImageView, from: imageURL, completion: { (error) in
                
                if let localError = error { print("AtMe Error:: Did not recieve downloaded UIImage. \(localError)"); return }
                print("AtMe:: Loaded an image for a message cell")
            })
        }
        
        
        if (message.sender == UserState.currentUser.username && messageContentReference != nil) { // Outgoing
            
            cell.bubbleView.backgroundColor = UIColor.white
            cell.messageTextView.textColor = UIColor.black
            
            messageContentReference?.frame = CGRect(x: tableView.bounds.width - messageSize.width - (MessageCell.horizontalInsetPadding + MessageCell.horizontalBubbleSpacing),
                                                    y: MessageCell.verticalInsetPadding + MessageCell.verticalBubbleSpacing,
                                                    width: messageSize.width,
                                                    height: messageSize.height)
            
            cell.bubbleView.frame = CGRect(x: tableView.bounds.width - messageSize.width - (MessageCell.horizontalInsetPadding + (2 * MessageCell.horizontalBubbleSpacing)),
                                           y: MessageCell.verticalInsetPadding,
                                           width: messageSize.width + (2 * MessageCell.horizontalBubbleSpacing),
                                           height: messageSize.height + (2 * MessageCell.verticalBubbleSpacing))
            
        } else { // Incoming
            
            cell.bubbleView.backgroundColor = Constants.Colors.primaryDark
            cell.messageTextView.textColor = UIColor.white
            
            messageContentReference?.frame = CGRect(x: MessageCell.horizontalInsetPadding + MessageCell.horizontalBubbleSpacing,
                                                    y: MessageCell.verticalInsetPadding + MessageCell.verticalBubbleSpacing,
                                                    width: messageSize.width,
                                                    height: messageSize.height)
            
            cell.bubbleView.frame = CGRect(x: MessageCell.horizontalInsetPadding,
                                           y: MessageCell.verticalInsetPadding,
                                           width: messageSize.width + (2 * MessageCell.horizontalBubbleSpacing),
                                           height: messageSize.height + (2 * MessageCell.verticalBubbleSpacing))
        }
        
        return cell
    }
    
    
    /** Given a string, determine the CGSize that should be able to comfortably fit this when displayed in a given font. */
    func sizeForString(_ string: String, maxWidth: CGFloat, font: UIFont) -> CGSize {
        
        let storage = NSTextStorage(string: string)
        let container = NSTextContainer(size: CGSize(width: maxWidth, height: 10000))
        let manager = NSLayoutManager()
        
        manager.addTextContainer(container)
        storage.addLayoutManager(manager)
        
        storage.addAttribute(NSFontAttributeName, value: font, range: NSMakeRange(0, storage.length))
        container.lineFragmentPadding = 0.0
        
        manager.glyphRange(for: container)
        let size = manager.usedRect(for: container).size
        
        //print("Size = \(size) > \t\t\"\(string)\"")
        return size
    }
}
