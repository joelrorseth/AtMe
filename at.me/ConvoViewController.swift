//
//  ConvoViewController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-02-18.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase

class ChatInputAccessoryView: UIInputView {
    private static let preferredHeight: CGFloat = 24.0
    
    @IBOutlet weak var expandingTextView: UITextView!
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: ChatInputAccessoryView.preferredHeight)
    }
    
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


class ConvoViewController: UITableViewController, AlertController {
    
    // Firebase references
    var messagesRef: FIRDatabaseReference?
    lazy var conversationsRef: FIRDatabaseReference = FIRDatabase.database().reference().child("conversations")
    lazy var pictureMessagesRef: FIRStorageReference = FIRStorage.storage().reference().child("pictureMessages")
    
    // Firebase handles
    private var newMessageRefHandle: FIRDatabaseHandle?
    
    // MARK: Storyboard
    @IBOutlet var chatInputAccessoryView: ChatInputAccessoryView!
    
    var messages: [Message] = []
    var convoId: String = ""
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.none
        formatter.timeStyle = DateFormatter.Style.short
        
        return formatter
    }()
    
    
    // Wrapper view controller for the custom input accessory view
    private let chatInputAccessoryViewController = UIInputViewController()
    
    override var inputAccessoryViewController: UIInputViewController? {
        // Ensure our input accessory view controller has it's input view set
        chatInputAccessoryView.translatesAutoresizingMaskIntoConstraints = false
        chatInputAccessoryViewController.inputView = chatInputAccessoryView
        
        // Return our custom input accessory view controller. You could also just return a UIView with
        // override func inputAccessoryView()
        return chatInputAccessoryViewController
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        let didBecome = super.becomeFirstResponder()
        
        //if conversation != nil {
            // We want the input accessory view to become focused when the view controller is pushed/displayed
            chatInputAccessoryView.expandingTextView.becomeFirstResponder()
        //}
        
        return didBecome
    }
    
    // MARK: IBAction methods
    // ==========================================
    // ==========================================
    /*@IBAction func didPressSend(_ sender: Any) {
        
        if (messageTextField.text == "" || messageTextField.text == nil) { return }
        
        let message = Message(
            imageURL: nil,
            sender: UserState.currentUser.username!,
            text: messageTextField.text!,
            timestamp: getCurrentTimestamp()
        )
        
        // Pass message along to be stored
        send(message: message)
        
        // Clear message text field and dismiss keyboard
        messageTextField.text = ""
        messageTextField.resignFirstResponder()
    }
    */

    // ==========================================
    // ==========================================
    @IBAction func didPressCameraIcon(_ sender: Any) {
        
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
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        
        self.tableView.backgroundColor = UIColor.groupTableViewBackground
        
        // Set some properties of UI elements
        //messageTextField.borderStyle = .none
        //tableView?.register(MessageCell.self, forCellWithReuseIdentifier: Constants.Storyboard.messageId)
        
        addKeyboardObservers()

        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Start observing changes in the Firebase database
        observeReceivedMessages()
    }
    
    
    // MARK: Managing messages
    // ==========================================
    // ==========================================
    func send(message: Message) {
        
        // Write the message to Firebase
        let randomMessageId = messagesRef!.childByAutoId().key
        
        // TODO: Refactor convoId to be an optional

        // Increment message count by 1
        // TODO: Look into better method of doing this. Look up Firebase Transcation
        
        conversationsRef.child(convoId).observeSingleEvent(of: .value, with: { snapshot in
            
            let incrementedValue = (snapshot.childSnapshot(forPath: "messagesCount").value as! Int) + 1
            FIRDatabase.database().reference(withPath: "conversations/\(self.convoId)/messagesCount").setValue(incrementedValue)
        })

        
        // Each message record (uniquely identified) will record sender and message text
        messagesRef?.child(randomMessageId).setValue(
            ["imageURL": message.imageURL, "sender" : message.sender, "text" : message.text, "timestamp" : message.timestamp]
        )
        
        // TODO: Possibly cache messages for certain amount of time / 3 messages
        // Look into solution to avoid loading sent messages from server (no point in that?)
    }
    
    // ==========================================
    // ==========================================
    private func addMessage(message: Message) {
        
        // Update data source
        messages.append(message)
        
        // Efficiently update by updating / inserting only the cells that need to be
        self.tableView.beginUpdates()
        self.tableView.insertRows(at: [IndexPath(row: messages.count - 1, section: 0)], with: .left)
        self.tableView.endUpdates()
        
        // TODO: Fix animation for initial message loading. Animation is kinda choppy
        self.tableView.scrollToRow(at: IndexPath.init(row: messages.count - 1, section: 0) , at: .bottom, animated: true)
    }
    
    // ==========================================
    // ==========================================
    private func observeReceivedMessages() {

        let messagesQuery = messagesRef!.queryLimited(toLast: 25)
        
        // This closure is triggered once for every existing record found, and for each record added here
        newMessageRefHandle = messagesQuery.observe(FIRDataEventType.childAdded, with: { (snapshot) in
            
            var imageURL: String?
            var text: String?
            
            // Unwrap picture message url or text message, can and must always be only one or the other
            if let imageURLValue = snapshot.childSnapshot(forPath: "imageURL").value as? String {
                imageURL = imageURLValue
            }
            
            if let textValue = snapshot.childSnapshot(forPath: "text").value as? String {
                text = textValue
            }
            
            let sender = snapshot.childSnapshot(forPath: "sender").value as! String
            let timestamp = snapshot.childSnapshot(forPath: "timestamp").value as! String

            // Add message to local messages cache
            self.addMessage(message: Message(imageURL: imageURL, sender: sender, text: text, timestamp: timestamp))
        })
    }
    

    
    // MARK: Keyboard Handling
    // ==========================================
    // ==========================================
    private func addKeyboardObservers() {
    
        
        // Add gesture recognizer to handle tapping outside of keyboard
        let dismissKeyboardTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(dismissKeyboardTap)
    }

    
    // ==========================================
    // ==========================================
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    
    // MARK: Additional functions
    // ==========================================
    // ==========================================
    func getCurrentTimestamp() -> String {
        return dateFormatter.string(from: Date())
    }
    
    // ==========================================
    // ==========================================
    deinit {
        if let handle = newMessageRefHandle {
            messagesRef?.removeObserver(withHandle: handle)
            print("AT.ME:: Removed observer with handle \(handle) in ConvoViewController")
        }
    }
}


// MARK: UIImagePickerControllerDelegate
extension ConvoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // ==========================================
    // ==========================================
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        guard let uid = UserState.currentUser.uid else { return }
        let path = uid + "/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
        
        // Extract the image after editing, upload to database as Data object
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            if let data = convertImageToData(image: image) {
                
                DatabaseController.uploadImage(data: data, to: pictureMessagesRef.child(path), completion: { (error) in
                    if let error = error {
                        print("AT.ME:: Error uploading picture message to Firebase. \(error.localizedDescription)")
                        return
                    }
                    
                    // Now that image has uploaded, officially send the message record to the database with storage URL
                    print("AT.ME:: Image uploaded successfully to \(self.pictureMessagesRef.child(path).fullPath)")
                    self.send(message: Message(
                        imageURL: self.pictureMessagesRef.child(path).fullPath,
                        sender: UserState.currentUser.username!,
                        text: nil,
                        timestamp: self.getCurrentTimestamp()))
                })
                
            } else { print("AT.ME:: Error extracting image from source") }
        } else { print("AT.ME:: Error extracting edited UIImage from info dictionary") }
        
        dismiss(animated: true)
    }
    
    // ==========================================
    // ==========================================
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}


// MARK: Table View Delegate
extension ConvoViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return messages.count }

    
    // ==========================================
    // ==========================================
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
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
            messageSize = sizeForString(text, maxWidth: tableView.bounds.width * 0.7, font: Constants.Fonts.regularFont)
            messageContentReference = cell.messageTextView
            
            cell.messageTextView.text = message.text
        }
        
        // Picture Message
        if let imageURL = message.imageURL {
            
            messageSize = CGSize(width: 200, height: 200)
            messageContentReference = cell.messageImageView
            
            DatabaseController.downloadImage(from: FIRStorage.storage().reference().child(imageURL), completion: { (error, image) in
                
                if let localError = error { print("At.ME Error:: Did not recieve downloaded UIImage. \(localError)"); return }
                if let localImage = image { cell.messageImageView.image = localImage }
            })
        }
        
        
        if (message.sender == UserState.currentUser.username! && messageContentReference != nil) { // Outgoing
            
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
            
            cell.bubbleView.backgroundColor = Constants.Colors.primaryColor
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
    
    // ==========================================
    // ==========================================
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
    
    // ==========================================
    // ==========================================
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if let text = messages[indexPath.row].text {
            return sizeForString(text, maxWidth: tableView.bounds.width * 0.7, font: Constants.Fonts.regularFont).height + (2 * MessageCell.verticalBubbleSpacing) + (2 * MessageCell.verticalInsetPadding)
        }
        
        if let _ = messages[indexPath.row].imageURL {
            return 200 + (2 * MessageCell.verticalBubbleSpacing) + (2 * MessageCell.verticalInsetPadding)

        }
        
        return 0
    }
}
