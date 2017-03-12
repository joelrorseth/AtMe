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
    
    var usernameResults: [String] = []
    
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
        return usernameResults.count
    }
    
    // ==========================================
    // ==========================================
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Populate table with results from lookup
        let cell = usersTableView.dequeueReusableCell(withIdentifier: "UserInfoCell", for: indexPath) as! UserInfoCell
        cell.displayName.text = "DISPLAY_NAME"
        cell.usernameLabel.text = usernameResults[indexPath.row]
        
        return cell
    }
    
    // ==========================================
    // ==========================================
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! UserInfoCell
        print("AT.ME:: Creating conversation with user wwith username: \(cell.usernameLabel.text!)")
    }
    
    
    // MARK: UISearchBarDelegate
    // ==========================================
    // ==========================================
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        // Search registered Firebase users that match search criteria
        registeredUsernamesRef.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in

            
            // If we find username registered, list it in table view
            if (snapshot.hasChild(searchBar.text!)) {
                
                // Begin updates to table view, delete the most recently found user if currently shown
                self.usersTableView.beginUpdates()
                if (!(self.usernameResults.count == 0)) {
                    self.usersTableView.deleteRows(at: [IndexPath.init(row: self.usernameResults.count - 1, section: 0)], with: .automatic)
                }
                
                // Update the data source, then insert the rows into the table view
                self.usernameResults = ["\(searchBar.text!)"]
                self.usersTableView.insertRows(at: [IndexPath.init(row: self.usernameResults.count - 1, section: 0)], with: .automatic)
                
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
