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
    
    
    // MARK: View
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        tableView.tintColor = Constants.Colors.primaryColor
        
        // Establish bar button items in conversations view
        self.navigationItem.title = "at.me"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: nil)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: nil)
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
}
