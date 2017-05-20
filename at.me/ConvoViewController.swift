//
//  ConvoViewController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-02-18.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase

class ConvoViewController: UIViewController, AlertController {
    
    // Firebase references
    var messagesRef: FIRDatabaseReference?
    
    // Firebase handles
    private var newMessageRefHandle: FIRDatabaseHandle?
    
    // MARK: Storyboard
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var messageToolbar: UIToolbar!
    @IBOutlet weak var messageToolbarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageCollectionView: UICollectionView!
    
    var messages: [Message] = []
    var convoId: String! = ""
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.none
        formatter.timeStyle = DateFormatter.Style.short
        
        return formatter
    }()
    
    // ==========================================
    // ==========================================
    @IBAction func didPressSend(_ sender: Any) {
        
        if (messageTextField.text == "" || messageTextField.text == nil) { return }
        
        let message = Message(
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
        
        // Set some properties of UI elements
        messageTextField.borderStyle = .none
        messageCollectionView?.register(MessageCell.self, forCellWithReuseIdentifier: Constants.Storyboard.messageId)
        
        addKeyboardObservers()
        
        // Establish a flow layout with spacing for collection view of messages
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 14
        messageCollectionView.setCollectionViewLayout(layout, animated: true)
        
        // Start observing changes in the Firebase database
        observeReceivedMessages()
    }
    
    
    // MARK: Managing messages
    // ==========================================
    // ==========================================
    private func send(message: Message) {
        
        // Write the message to Firebase
        let randomMessageId = messagesRef!.childByAutoId().key
        
        // Each message record (uniquely identified) will record sender and message text
        messagesRef?.child(randomMessageId).setValue(
            ["sender" : message.sender, "text" : message.text, "timestamp" : message.timestamp]
        )
        
        // TODO: Possibly cache messages for certain amount of time / 3 messages
        // Look into solution to avoid loading sent messages from server (no point in that?)
    }
    
    // ==========================================
    // ==========================================
    private func addMessage(message: Message) {
        
        // Add text from textfield to temp array, insert row into collection view
        messages.append(message)
        messageCollectionView.insertItems(at: [IndexPath(row: messages.count - 1, section: 0)] )
    }
    
    // ==========================================
    // ==========================================
    private func observeReceivedMessages() {

        let messagesQuery = messagesRef!.queryLimited(toLast: 25)
        
        // This closure is triggered once for every existing record found, and for each record added here
        newMessageRefHandle = messagesQuery.observe(FIRDataEventType.childAdded, with: { (snapshot) in
            
            let sender = snapshot.childSnapshot(forPath: "sender").value as! String
            let text = snapshot.childSnapshot(forPath: "text").value as! String
            let timestamp = snapshot.childSnapshot(forPath: "timestamp").value as! String
            
            print("AT.ME:: Just retrieved message from \(sender): \(text)")
            self.addMessage(message: Message(sender: sender, text: text, timestamp: timestamp))
            
            
//            // Extract fields from this message record
//            // Potentially unwrap optionals this way to avoid app crash
//            // Message records should ALWAYS have sender and text records though...
//
//            if let sender = snapshot.childSnapshot(forPath: "sender").value as! String!,
//                let text = snapshot.childSnapshot(forPath: "text").value as! String! {
//                
//                print("AT.ME:: Just retrieved message from \(sender): \(text)")
//                self.addMessage(message: Message(sender: sender, text: text))
//            }
        })
    }
    

    
    // MARK: Keyboard Handling
    // ==========================================
    // ==========================================
    private func addKeyboardObservers() {
        
        // Add observers for when the keyboard appears and disappears
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // Add gesture recognizer to handle tapping outside of keyboard
        let dismissKeyboardTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(dismissKeyboardTap)
    }
    
    // ==========================================
    // ==========================================
    func keyboardWillShow(notification: NSNotification) {
        
        // Extract frame size of the keyboard
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        // Set toolbar bottom constraint to match keyboard height
        self.messageToolbarBottomConstraint.constant = keyboardFrame.size.height
        self.view.layoutIfNeeded()
    }
    
    // ==========================================
    // ==========================================
    func keyboardWillHide(notification: NSNotification) {
        
        // Put the message toolbar back at the bottom
        self.messageToolbarBottomConstraint.constant = 0.0
        self.view.layoutIfNeeded()
    }
    
    // ==========================================
    // ==========================================
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    
    // MARK: Additional functions
    // ==========================================
    // ==========================================
    private func getCurrentTimestamp() -> String {
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

extension ConvoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
}

extension ConvoViewController: UICollectionViewDelegate {
    
    // ==========================================
    // ==========================================
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // ==========================================
    // ==========================================
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    // ==========================================
    // ==========================================
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(8, 0, 0, 0)
    }
}


extension ConvoViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: Collection View
    
    // ==========================================
    // ==========================================
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Dequeue a custom cell for collection view
        let cell = messageCollectionView.dequeueReusableCell(withReuseIdentifier: Constants.Storyboard.messageId, for: indexPath) as! MessageCell
        let message = messages[indexPath.row]
        
        // Important: Set message text in the cell
        cell.messageTextView.font = UIFont.systemFont(ofSize: 14)
        cell.messageTextView.text = message.text
        
        // Calculate how large the bubble will need to be to house the message
        let messageFrame = NSString(string: message.text).boundingRect(
            with: CGSize(width: (view.bounds.size.width * 0.72), height: 1000),
            options: NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin),
            attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)],
            context: nil
        )
        
        // CASE 1: OUTGOING
        if (message.sender == UserState.currentUser.username!) {

            // Set bubble and text frames
            cell.messageTextView.frame = CGRect(
                x: ((view.frame.width - (messageFrame.width + 11 + 20))),
                y: 1,
                width: messageFrame.width + 16 - 5,
                height: messageFrame.height + 20
            )
            
            cell.bubbleView.frame = CGRect(
                x: (view.frame.width - 15) - (messageFrame.width + 11 + 20) + 5 + 5,
                y: -4,
                width: messageFrame.width + 11 + 20 - 5 - 5,
                height: messageFrame.height + 26
            )
            
            // Set bubble attributes
            cell.bubbleView.backgroundColor = UIColor.white
            cell.messageTextView.textColor = UIColor.black
        }
        
        // CASE 2: INCOMING
        else {
            
            // Set bubble and text frames
            cell.messageTextView.frame = CGRect(
                x: 15 + 5,
                y: 1,
                width: messageFrame.width + 11,
                height: messageFrame.height + 20
            )
            cell.bubbleView.frame = CGRect(
                x: 15,
                y: -4,
                width: messageFrame.width + 20 + 11 - 10,
                height: messageFrame.height + 26
            )
            
            // Set bubble attributes
            cell.bubbleView.backgroundColor = UIColor.darkGray
            cell.messageTextView.textColor = UIColor.white
        }

        return cell
    }
    
    // ==========================================
    // ==========================================
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if messages[indexPath.row].text == "" {
            return CGSize(width: view.frame.width, height: 100)
        }
        
        // Obtain a frame for the size of the message to be displayed
        let messageFrame = NSString(string: messages[indexPath.row].text).boundingRect(
            with: CGSize(width: 250, height: 1000),
            options: NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin),
            attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)],
            context: nil
        )
        
        // Return size intended to house entire cell / message bubble
        return CGSize(width: view.frame.width, height: messageFrame.height + 20)
    }
}
