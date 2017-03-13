//
//  ChatListViewController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-02-18.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase

class ChatListViewController: UITableViewController {
    
    // Firebase references are used for read/write at referenced location
    private lazy var userConversationListRef: FIRDatabaseReference = FIRDatabase.database().reference().child("userConversationList")
    
    var activeConversations: [String] = []
    
    // MARK: View
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tintColor = Constants.Colors.primaryColor
        
        // Establish bar button items in conversations view
        let settingsIcon = UIImage(named: "settings")
        let settingsButton = UIBarButtonItem(image: settingsIcon, style: .plain, target: self, action: #selector(didTapSettings))
        

        self.navigationItem.leftBarButtonItem = settingsButton
        self.navigationItem.title = "@ Me"
        
        // Establish the current active conversations to populate the table view data source
        let currentUserUid = FIRAuth.auth()?.currentUser?.uid
        
        userConversationListRef.child(currentUserUid!).queryOrderedByKey().observe(.value, with: { snapshot in
            
            // Clear current list of convos
            self.activeConversations.removeAll()
            
            for item in snapshot.children {
                let convo = item as! FIRDataSnapshot
                
                // TODO: Change db model to store username in each conversation record value
                print("Child key for user is \(convo.key), value is \(convo.value as! String)")
                
                // Add username into table view data source
                self.activeConversations.append("\(convo.value as! String)")
            }

            self.tableView.reloadData()
        })
    }
    
    
    // MARK: Table View
    // ==========================================
    // ==========================================
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // ==========================================
    // ==========================================
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(80)
    }
    
    // ==========================================
    // ==========================================
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activeConversations.count
    }
    
    // ==========================================
    // ==========================================
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatListCell", for: indexPath)
        
        // TODO: Obtain most recent message for detail text
        // TODO: Design custom class to model a conversation cell
        cell.textLabel?.text = activeConversations[indexPath.row]
        
        return cell
    }
    
    
    // MARK: Functionality
    // ==========================================
    // ==========================================
    @objc private func didTapSettings() {
        
        self.performSegue(withIdentifier: "ShowSettings", sender: self)
    }
}
