//
//  ConvoViewController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-02-18.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase

class ConvoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // Firebase references
    private lazy var conversationsRef: FIRDatabaseReference = FIRDatabase.database().reference().child("conversations")
    
    // MARK: Storyboard
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var messageToolbar: UIToolbar!
    @IBOutlet weak var messageToolbarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageCollectionView: UICollectionView!
    
    var convoId: String! = ""

    
    // A sample array with messages to test the table view
    var messagesArrayTest = ["Hello, my name is Joel. I will be conducting your interview today.",
                             "Hi Joel, nice to meet you",
                             "For the first portion, we will be discussing your work history."]
    
    
    // ==========================================
    // ==========================================
    @IBAction func didPressSend(_ sender: Any) {
        
        if (messageTextField.text == "" || messageTextField.text == nil) { return }
        
        // Pass message along to be stored
        send(message: messageTextField.text!)
        
        // Add text from textfield to temp array, insert row into collection view
        messagesArrayTest.append(messageTextField.text!)
        messageCollectionView.insertItems(at: [IndexPath.init(row: messagesArrayTest.count - 1, section: 0)])
        
        // Clear message text field and dismiss keyboard
        messageTextField.text = ""
        messageTextField.resignFirstResponder()
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
    }
    
    
    // MARK: Sending & Receiving Messages
    // ==========================================
    // ==========================================
    private func send(message: String) {
        
        // Write the message to Firebase
        let messageId = conversationsRef.child("\(convoId!)/messages").childByAutoId().key
        
        // Each message record (uniquely identified) will record sender and message text
        conversationsRef.child("\(convoId!)/messages/\(messageId)/text").setValue(message)
        conversationsRef.child("\(convoId!)/messages/\(messageId)/sender").setValue(UserState.currentUser.username!)
        
        // Possibly add message to local array etc?
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
    
    
    // MARK: Collection View
    // ==========================================
    // ==========================================
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // ==========================================
    // ==========================================
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Dequeue a custom cell for collection view
        let cell = messageCollectionView.dequeueReusableCell(withReuseIdentifier: Constants.Storyboard.messageId, for: indexPath) as! MessageCell
        let message = messagesArrayTest[indexPath.row]
        
        // Important: Set message text in the cell
        cell.messageTextView.font = UIFont.systemFont(ofSize: 14)
        cell.messageTextView.text = message
        
        // Calculate how large the bubble will need to be to house the message
        let messageFrame = NSString(string: message).boundingRect(
            with: CGSize(width: (view.bounds.size.width * 0.72), height: 1000),
            options: NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin),
            attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)],
            context: nil
        )

        
        // CASE 1: INCOMING
        if ((arc4random_uniform(2)) == 1) {
            
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
        
            
        // CASE 2: OUTGOING
        else {
            
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
        
        return cell
    }
    
    // ==========================================
    // ==========================================
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if messagesArrayTest[indexPath.row] == "" {
            return CGSize(width: view.frame.width, height: 100)
        }
        
        // Obtain a frame for the size of the message to be displayed
        let messageFrame = NSString(string: messagesArrayTest[indexPath.row]).boundingRect(
            with: CGSize(width: 250, height: 1000),
            options: NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin),
            attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)],
            context: nil
        )
        
        // Return size intended to house entire cell / message bubble
        return CGSize(width: view.frame.width, height: messageFrame.height + 20)
    }
    
    // ==========================================
    // ==========================================
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messagesArrayTest.count
    }
    
    // ==========================================
    // ==========================================
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(8, 0, 0, 0)
    }
}
