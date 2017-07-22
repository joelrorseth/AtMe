//
//  ConvoViewController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-02-18.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase


// MARK: ChatInputAccessoryView class (Input View for message bar)
class ChatInputAccessoryView: UIInputView {
    
    private static let preferredHeight: CGFloat = 24.0
    @IBOutlet weak var expandingTextView: UITextView!
    
    
    /** Overridden variable which determines if current view contrller can become first responder. */
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    
    /** Asks the view to calculate and return the size that best fits the specified size. */
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: ChatInputAccessoryView.preferredHeight)
    }
    
    
    /** Set the natural size to contain all contents in this view */
    override var intrinsicContentSize: CGSize {
        var newSize = bounds.size
        
        if expandingTextView.bounds.size.height > 0.0 {
            newSize.height = expandingTextView.bounds.size.height + 20.0
        }
        
        if newSize.height < ChatInputAccessoryView.preferredHeight || newSize.height > 120.0 {
            newSize.height = ChatInputAccessoryView.preferredHeight
        }
        
        return newSize
    }
}



// MARK: ConvoViewController Class
class ConvoViewController: UITableViewController, AlertController {
    
    // Firebase references
    var conversationRef: DatabaseReference?
    var messagesRef: DatabaseReference? = nil
        
    var observingMessages = false
    var messages: [Message] = []
    var notificationIDs: [String] = []
    var currentMessageCountLimit = Constants.Limits.messageCountStandardLimit
    
    
    /** Overridden variable which determines if current view contrller can become first responder. */
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    
    // MARK: Storyboard
    @IBOutlet weak var chatInputAccessoryView: ChatInputAccessoryView!
    
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
    
    // Wrapper view controller for the custom input accessory view
    let chatInputAccessoryViewController = UIInputViewController()
    
    
    /** Overridden variable which sets the UIInputViewController input accessory for this view controller. */
    override var inputAccessoryViewController: UIInputViewController? {
        
        // Ensure our input accessory view controller has it's input view set
        chatInputAccessoryView.translatesAutoresizingMaskIntoConstraints = false
        chatInputAccessoryViewController.inputView = chatInputAccessoryView
        
        // Return our custom input accessory view controller. You could also just return a UIView with
        // override func inputAccessoryView()
        return chatInputAccessoryViewController
    }
    
    
    // MARK: IBAction methods
    /** Action method which fires when the user taps 'Send'. */
    @IBAction func didPressSend(_ sender: Any) {
        
        if (chatInputAccessoryView.expandingTextView.text == "" ||
            chatInputAccessoryView.expandingTextView.text == nil) { return }
        
        let message = Message(
            imageURL: nil,
            sender: UserState.currentUser.username,
            text: chatInputAccessoryView.expandingTextView.text!,
            timestamp: Date()
        )
        
        // Pass message along to be stored
        send(message: message)
        
        // Clear message text field and dismiss keyboard
        chatInputAccessoryView.expandingTextView.text = ""
        chatInputAccessoryView.expandingTextView.resignFirstResponder()
    }
    
    
    /** Action method which fires when the user taps the camera icon. */
    @IBAction func didPressCameraIcon(_ sender: Any) {
        
        chatInputAccessoryView.expandingTextView.resignFirstResponder()
        
        // Create picker, and set this controller as delegate
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        // Call AlertController method to display ActionSheet allowing Camera or Photo Library selection
        // Use callback to set picker source type determined in the alert controller
        
        presentPhotoSelectionPrompt(completion: { (sourceType: UIImagePickerControllerSourceType) in
            
            picker.sourceType = sourceType
            self.present(picker, animated: true, completion: nil)
        })
    }
    
    
    // MARK: View
    /** Overridden method called after view controller's view is loaded into memory. */
    override func viewDidLoad() {
        
        chatInputAccessoryView.expandingTextView.inputAccessoryView = chatInputAccessoryView
        
        tableView.backgroundColor = UIColor.groupTableViewBackground
        tableView.allowsSelection = false
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadWithMoreMessages), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl
        
        addKeyboardObservers()
    }
    
    
    
    /** Overridden method called when view controller will been removed from view hierarchy. */
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // If this view controller is being popped off navigation stack, then remove all observers
        if self.isMovingFromParentViewController { removeAllObservers() }
    }
    
    
    // MARK: Managing messages
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
        
        // Update data source
        messages.append(message)
        
        // Efficiently update by updating / inserting only the cells that need to be
        //self.tableView.beginUpdates()
        self.tableView.insertRows(at: [IndexPath(row: messages.count - 1, section: 0)], with: .none)
        self.tableView.scrollToRow(at: IndexPath.init(row: messages.count - 1, section: 0) , at: .bottom, animated: false)
        //self.tableView.endUpdates()
        
        // TODO: Fix animation for initial message loading. Animation is kinda choppy
        //print("Scrolling to row \(IndexPath.init(row: messages.count - 1, section: 0))")
    }
    
    
    // TODO: In future update, refactor into DatabaseController
    /** Update the current user's 'last seen timestamp' for a given conversation in the database. */
    private func updateLastSeenTimestamp(convoID: String) {
        
        conversationRef?.child("lastSeen/\(UserState.currentUser.uid)").setValue(Date().timeIntervalSince1970)
    }
    
    
    // MARK: Observers
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
        messagesQuery?.observe(DataEventType.childAdded, with: { snapshot in
                        
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
        
        conversationRef?.child("activeMembers").observe(DataEventType.childAdded, with: { snapshot in
            
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
        
        messagesRef?.removeAllObservers()
        conversationRef?.child("activeMembers").removeAllObservers()
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
    
    
    // MARK: Keyboard Handling
    /** Add gesture recognizer to track dismiss keyboard area */
    private func addKeyboardObservers() {
        
        // Add gesture recognizer to handle tapping outside of keyboard
        let dismissKeyboardTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.tableView.addGestureRecognizer(dismissKeyboardTap)
    }
    
    
    /** Dismiss the custom keyboard (the input accessory) */
    func dismissKeyboard() {
        chatInputAccessoryViewController.dismissKeyboard()
        chatInputAccessoryView.expandingTextView.resignFirstResponder()
    }
    
    
    // MARK: Additional functions
    /**
     Obtains a timestamp of the current moment in time (described as the interval from 1970 until now)
     - returns: A TimeInterval object representing the time interval since 1970
     */
    func getCurrentTimestamp() -> TimeInterval {
        return Date().timeIntervalSince1970
    }
}


// MARK: UIImagePickerControllerDelegate
extension ConvoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // TODO: In future update, refactor
    /** Called when media has been selected by the user in the image picker. */
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if convoId == "" { dismiss(animated: true, completion: nil) }
        let path = "conversations/\(convoId)/images/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
        
        // Extract the image after editing, upload to database as Data object
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            if let data = convertImageToData(image: image) {
                
                DatabaseController.uploadImage(data: data, to: path, completion: { (error) in
                    if let error = error {
                        print("AtMe:: Error uploading picture message to Firebase. \(error.localizedDescription)")
                        self.dismiss(animated: true)
                        return
                    }
                    
                    // Now that image has uploaded, officially send the message record to the database with storage URL
                    let message = Message(imageURL: path, sender: UserState.currentUser.username, text: nil, timestamp: Date())
                    self.send(message: message)
                    self.dismiss(animated: true)
                })
                
            } else { print("AtMe:: Error extracting image from source") }
        } else { print("AtMe:: Error extracting edited UIImage from info dictionary") }
    }
    
    
    /** Called if and when the user has cancelled the image picking operation. */
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}

extension ConvoViewController: UITextViewDelegate {
    
    /** Delegate method which fires when the specified text view has begun editing. */
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        textView.inputAccessoryView = chatInputAccessoryView
        
        self.chatInputAccessoryView.expandingTextView.textColor = UIColor.darkGray
        
        // TODO: Test and refactor scrolling to clean up animation, avoid scrolling to inexistent rows
        if (messages.count != 0) {
            self.tableView.scrollToRow(at: IndexPath.init(row: messages.count - 1, section: 0) , at: .bottom, animated: true)
        }
            
        if (self.chatInputAccessoryView.expandingTextView.text == "Enter a message") {
            self.chatInputAccessoryView.expandingTextView.text = ""
        }
    }
    
    
    /** Delegate method which fires when the specified text view has ended editing. */
    func textViewDidEndEditing(_ textView: UITextView) {
        self.chatInputAccessoryView.expandingTextView.textColor = UIColor.gray
        self.chatInputAccessoryViewController.dismissKeyboard()
        
        if (self.chatInputAccessoryView.expandingTextView.text == "") {
            self.chatInputAccessoryView.expandingTextView.text = "Enter a message"
        }
    }
}


// MARK: Table View Delegate
extension ConvoViewController {
    
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
