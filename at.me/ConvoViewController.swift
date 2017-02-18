//
//  ConvoViewController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-02-18.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

class ConvoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: Storyboard
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var messageToolbar: UIToolbar!
    @IBOutlet weak var messageToolbarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageTableView: UITableView!
    
    // A sample array with messages to test the table view
    var messagesArrayTest = ["Hello", "Hi nice to meet you", "My name is John"]
    
    // ==========================================
    // ==========================================
    @IBAction func didPressSend(_ sender: Any) {
        
        // TODO: Handle message content
        messagesArrayTest.append(messageTextField.text!)
        messageTableView.beginUpdates()
        messageTableView.insertRows(at: [IndexPath.init(row: messagesArrayTest.count - 1, section: 0)], with: UITableViewRowAnimation.automatic)
        messageTableView.endUpdates()
        
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
    
    
    // MARK: Table View
    // ==========================================
    // ==========================================
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messagesArrayTest.count
    }
    
    // ==========================================
    // ==========================================
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // For quick test, deque alternating incoming and outgoing messages
        let messageType = (indexPath.row % 2 == 1) ? "incomingMessage" : "outgoingMessage"
        
        // Return said cell dequeued from table view
        if (messageType == "incomingMessage") {
            let cell = messageTableView.dequeueReusableCell(withIdentifier: messageType, for: indexPath) as! IncomingMessageCell
            cell.message.text = messagesArrayTest[indexPath.row]
            return cell
        } else {
            let cell = messageTableView.dequeueReusableCell(withIdentifier: messageType, for: indexPath) as! OutgoingMessageCell
            cell.message.text = messagesArrayTest[indexPath.row]
            return cell
        }
    }
}

