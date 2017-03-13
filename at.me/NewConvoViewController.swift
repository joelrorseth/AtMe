//
//  NewConvoViewController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-02-25.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase

class NewConvoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var usersSearchBar: UISearchBar!
    @IBOutlet weak var usersTableView: UITableView!
    
    private lazy var registeredUsernamesRef: FIRDatabaseReference = FIRDatabase.database().reference().child("registeredUsernames")
    private lazy var userConversationListRef: FIRDatabaseReference = FIRDatabase.database().reference().child("userConversationList")
    
    var searchResults: [User] = []
    
    // ==========================================
    // ==========================================
    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: View Lifecycle
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        
        self.usersSearchBar.delegate = self
    }

    
    // MARK: Table View
    // ==========================================
    // ==========================================
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // ==========================================
    // ==========================================
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(56)
    }
    
    // ==========================================
    // ==========================================
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    // ==========================================
    // ==========================================
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Populate table with results from lookup
        let cell = usersTableView.dequeueReusableCell(withIdentifier: "UserInfoCell", for: indexPath) as! UserInfoCell
        cell.displayName.text = searchResults[0].username
        cell.usernameLabel.text = searchResults[0].uid
        cell.uid = searchResults[0].uid
        
        return cell
    }
    
    // ==========================================
    // ==========================================
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! UserInfoCell
        print("AT.ME:: Creating conversation with user wwith username: \(cell.usernameLabel.text!)")
        
        // Retrieve uid of selected user, create conversation record in Firebase
        if let selectedUid = cell.uid {
            let currentUserUid = (FIRAuth.auth()?.currentUser?.uid)!
            
            // For both users separately, record the existence of an active conversation with the other
            userConversationListRef.child(currentUserUid).child(selectedUid).setValue(true)
            userConversationListRef.child(selectedUid).child(currentUserUid).setValue(true)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    
    // MARK: UISearchBarDelegate
    // ==========================================
    // ==========================================
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        // Search registered Firebase users that match search criteria
        registeredUsernamesRef.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in

            
            // If we find username registered, list it in table view
            if (snapshot.hasChild(searchBar.text!)) {
                
                // Obtain uid and username
                let username = searchBar.text!
                let uid = snapshot.childSnapshot(forPath: searchBar.text!).value as! String
                
                // Begin updates to table view, delete the most recently found user if currently shown
                self.usersTableView.beginUpdates()
                if (!(self.searchResults.count == 0)) {
                    self.usersTableView.deleteRows(at: [IndexPath.init(row: self.searchResults.count - 1, section: 0)], with: .automatic)
                }
                
                // Update the data source, then insert the rows into the table view
                self.searchResults = [User(username: username, uid: uid)]
                self.usersTableView.insertRows(at: [IndexPath.init(row: self.searchResults.count - 1, section: 0)], with: .automatic)
                
                self.usersTableView.endUpdates()
                
            } else {
                
                // Alert user that the user name specified was not found
                let ac = UIAlertController(title: "User Not Found", message: "Please enter another username", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(ac, animated: true) { self.usersSearchBar.becomeFirstResponder() }
            }
        })
    }
}
