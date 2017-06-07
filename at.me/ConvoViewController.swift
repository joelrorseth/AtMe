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
    lazy var conversationsRef: FIRDatabaseReference = FIRDatabase.database().reference().child("conversations")
    lazy var pictureMessagesRef: FIRStorageReference = FIRStorage.storage().reference().child("pictureMessages")
    
    // Firebase handles
    private var newMessageRefHandle: FIRDatabaseHandle?
    
    // MARK: Storyboard
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var messageToolbar: UIToolbar!
    @IBOutlet weak var messageToolbarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageCollectionView: UICollectionView!
    
    var messages: [Message] = []
    var convoId: String = ""
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.none
        formatter.timeStyle = DateFormatter.Style.short
        
        return formatter
    }()
    
    
    // MARK: IBAction methods
    // ==========================================
    // ==========================================
    @IBAction func didPressSend(_ sender: Any) {
        
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
        
        self.messageCollectionView.backgroundColor = UIColor.groupTableViewBackground
        
        // Establish a flow layout with spacing for collection view of messages
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 14
        messageCollectionView.setCollectionViewLayout(layout, animated: true)
        
        // Set some properties of UI elements
        messageTextField.borderStyle = .none
        messageCollectionView?.register(MessageCell.self, forCellWithReuseIdentifier: Constants.Storyboard.messageId)
        
        addKeyboardObservers()

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
        
        // Add text from textfield to temp array, insert row into collection view
        messages.append(message)
        messageCollectionView.insertItems(at: [IndexPath(row: messages.count - 1, section: 0)] )
        //messageCollectionView.scrollToItem(at: IndexPath(row: messages.count - 1, section: 0) , at: UICollectionViewScrollPosition.bottom, animated: false)
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


// MARK: Collection View Delegate
extension ConvoViewController: UICollectionViewDelegate {
    
    // ==========================================
    // ==========================================
    func numberOfSections(in collectionView: UICollectionView) -> Int { return 1 }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { return messages.count }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat { return 10 }
}


// MARK: Collection View Data Source
extension ConvoViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    
    // TODO: Major refactoring!!!
    // ==========================================
    // ==========================================
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Dequeue a custom cell for collection view
        let cell = messageCollectionView.dequeueReusableCell(withReuseIdentifier: Constants.Storyboard.messageId, for: indexPath) as! MessageCell
        let message = messages[indexPath.row]
        
        
        // Set the background color of the message
        if (message.sender == UserState.currentUser.username!) {
            cell.bubbleView.backgroundColor = UIColor.white
            cell.messageTextView.textColor = UIColor.black
        } else {
            cell.bubbleView.backgroundColor = Constants.Colors.primaryColor
            cell.messageTextView.textColor = UIColor.white
        }
        
        
        // CASE 1/2: Normal Text Message
        // ----------------------------------------------------
        if let text = message.text {
            
            // Set text field embedded in cell to show message
            cell.messageTextView.text = message.text
            
            // Calculate how large the bubble will need to be to house the message
            let messageFrame = NSString(string: text).boundingRect(
                with: CGSize(width: (view.bounds.size.width * 0.72), height: 1000),
                options: NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin),
                attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: CGFloat(Constants.Text.defaultTextSize))],
                context: nil
            )
            
            if (message.sender == UserState.currentUser.username!) {    // CASE 1: OUTGOING
                
                cell.messageTextView.frame = CGRect(x: view.frame.width - (messageFrame.width + 31),
                                                    y: 0,
                                                    width: messageFrame.width + 11,
                                                    height: messageFrame.height + 20)
                cell.bubbleView.frame = CGRect(x: (view.frame.width - 15) - (messageFrame.width + 31) + 10,
                                               y: 0,
                                               width: messageFrame.width + 21,
                                               height: messageFrame.height + 18)

            } else {    // CASE 2: INCOMING
                
                // Set bubble and text frames
                cell.messageTextView.frame = CGRect(x: 20, y: 0, width: messageFrame.width + 11, height: messageFrame.height + 20)
                cell.bubbleView.frame = CGRect(x: 15, y: 0, width: messageFrame.width + 21, height: messageFrame.height + 18)
            }
            
            return cell
        }
        
        
        // CASE 2/2: Picture Message
        // ----------------------------------------------------
        if let imageURL = message.imageURL {
            
            let messageFrame = CGRect(x: -71, y: 0, width: 200, height: 200)
            DatabaseController.downloadImage(from: FIRStorage.storage().reference().child(imageURL), completion: { (error, image) in
                if let localError = error {
                    print("At.ME Error:: Did not recieve downloaded UIImage. \(localError)")
                    return
                }
                
                if let localImage = image {
                    cell.messageImageView.image = localImage
                }
            })
            
            if (message.sender == UserState.currentUser.username!) {    // CASE 1: OUTGOING
                cell.bubbleView.frame = CGRect(x: view.frame.width - 300, y: 0, width: 200, height: 200)
                cell.messageImageView.frame = cell.bubbleView.frame
            
            }   else {  // CASE 2: INCOMING
                cell.bubbleView.frame = messageFrame
                cell.messageImageView.frame = messageFrame
            }

            return cell
        }

        return cell
    }
    
    // ==========================================
    // ==========================================
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // Message at this location is a text message
        if let text = messages[indexPath.row].text {
            
            // Use text size to determine message bubble frame
            let messageFrame = NSString(string: text).boundingRect(
                with: CGSize(width: (view.bounds.size.width * 0.72), height: 1000),
                options: NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin),
                attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: CGFloat(Constants.Text.defaultTextSize))],
                context: nil
            )
            
            // Return size intended to house entire cell / message bubble
            return CGSize(width: view.frame.width, height: messageFrame.height + 12)
        }
            
            // Message at this location is a picture message
        else {
            
            // TODO: Calculate size for image
            return CGSize(width: 200, height: 200)
        }
    }
}
