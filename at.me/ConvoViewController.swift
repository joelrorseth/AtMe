//
//  ConvoViewController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-02-18.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

class ConvoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: Storyboard
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var messageToolbar: UIToolbar!
    @IBOutlet weak var messageToolbarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageCollectionView: UICollectionView!

    
    // A sample array with messages to test the table view
    var messagesArrayTest = ["Hello", "Hi nice to meet you", "My name is John"]
    
    // ==========================================
    // ==========================================
    @IBAction func didPressSend(_ sender: Any) {
        
        // Add text from textfield to temp array, insert row into collection view
        messagesArrayTest.append(messageTextField.text!)
        messageCollectionView.insertItems(at: [IndexPath.init(row: messagesArrayTest.count - 1, section: 0)])
        
        // Clear message text field
        messageTextField.text = ""
        
        // Dismiss keyboard now that message is "sent"
        messageTextField.resignFirstResponder()
    }

    
    // MARK: View
    // ==========================================
    // ==========================================
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Add observers to know when to move message toolbar
        addKeyboardObservers()
        messageCollectionView?.register(MessageCell.self, forCellWithReuseIdentifier: Constants.Storyboard.messageId)
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
        cell.messageTextView.text = message
        
        // Calculate how large the bubble will need to be to house the message
        let messageFrame = NSString(string: message).boundingRect(
            with: CGSize(width: 250, height: 1000),
            options: NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin),
            attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)],
            context: nil
        )

        
        // CASE 1: INCOMING
        if ((arc4random_uniform(2)) == 1) {
            
            // Set bubble and text frames
            cell.messageTextView.frame = CGRect(
                                        x: 28,
                                        y: 0,
                                        width: messageFrame.width + 16,
                                        height: messageFrame.height + 20
            )
            cell.bubbleView.frame = CGRect(
                                        x: 10,
                                        y: -4,
                                        width: messageFrame.width + 40,
                                        height: messageFrame.height + 26
            )
            
            // Set bubble attributes
            cell.bubbleImageView.image = MessageCell.incomingBubble
            cell.bubbleImageView.tintColor = UIColor.lightGray
            cell.messageTextView.textColor = UIColor.black
        }
        
            
        // CASE 2: OUTGOING
        else {
            
            // Set bubble and text frames
            cell.messageTextView.frame = CGRect(
                                        x: view.frame.width - messageFrame.width - 34,
                                        y: 0,
                                        width: messageFrame.width + 16,
                                        height: messageFrame.height + 20
            )
            cell.bubbleView.frame = CGRect(
                                        x: view.frame.width - messageFrame.width - 44,
                                        y: -4,
                                        width: messageFrame.width + 34,
                                        height: messageFrame.height + 26
            )
            
            // Set bubble attributes
            cell.bubbleImageView.image = MessageCell.outgoingBubble
            cell.bubbleImageView.tintColor = Constants.Colors.primaryColor
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
            attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 15)],
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
