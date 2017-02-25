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
    private lazy var conversationsRef: FIRDatabaseReference = FIRDatabase.database().reference().child("conversations")
    
    // MARK: View
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tintColor = Constants.Colors.primaryColor
        
        // Establish bar button items in conversations view
        let logoutButton = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout))
        logoutButton.tintColor = UIColor.black
        self.navigationItem.leftBarButtonItem = logoutButton
        
        self.navigationItem.title = "@ Me"
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
        return 3
    }
    
    // ==========================================
    // ==========================================
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "ChatListCell", for: indexPath)
    }
    
    
    // MARK: Functionality
    // ==========================================
    // ==========================================
    @objc private func logout() {
        
        do {
            try FIRAuth.auth()?.signOut()
            dismiss(animated: true, completion: {
                print("<<<< AT.ME::DEBUG >>>>:: Successfully logged out")
            })
            
        } catch let error as NSError {
            print("<<<< AT.ME::DEBUG >>>>:: \(error.localizedDescription)")
        }
    }
}
