//
//  NewConvoViewController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-02-25.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase

class NewConvoViewController: UIViewController, UISearchBarDelegate, AlertController {
    
    lazy var authManager = AuthController()
    lazy var databaseManager = DatabaseController()
    
    @IBOutlet weak var usersSearchBar: UISearchBar!
    @IBOutlet weak var usersTableView: UITableView!
    
    var searchResults: [UserProfile] = []
    
    
    /** Action method which fires when the 'Cancel' button was tapped. */
    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - View
    /** Overridden method called after view controller's view is loaded into memory. */
    override func viewDidLoad() {
        
        // Set up search bar, ask keyboard to appear when view is loaded
        self.usersSearchBar.delegate = self
        self.usersSearchBar.becomeFirstResponder()
        
        usersSearchBar.barTintColor = Constants.Colors.primaryDark
        usersSearchBar.isTranslucent = false
        
        self.title = "New Conversation"
        
        // Little trick to hide empty cells from table view
        // TODO: Add suggestions to start a convo instead of a blank screen
        self.usersTableView.tableFooterView = UIView()
        
        // Add gesture recognizer to handle tapping outside of keyboard
        let dismissKeyboardTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissKeyboardTap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(dismissKeyboardTap)
    }
    
    
    // MARK: - Search Bar + Results
    /** Delegate method which fires when the Search button on the specified UISearchBar was tapped. */
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        clearResults()
        guard let text = searchBar.text else { return }
        
        // Find all usernames containing search text
        // Order record by key (which are the usernames), then query for string bounded in range [text, text]
        
        
        authManager.searchForUsers(term: text, completion: { results in
            
            if !results.isEmpty {
                
                // One by one, obtain details of each user, and insert the result into table with more info
                self.authManager.findDetailsForUsers(results: results, completion: { user in
                    self.insertResult(user: user)
                })
            }
        })
    }
    
    
    /** Clears the table view (results) and associated data source. */
    private func clearResults() {
        
        searchResults.removeAll()
        usersTableView.reloadData()
    }
    
    
    /** Inserts a given UserProfile into the table view, done efficiently by only inserting what it needs to. 
     - parameters:
        user: The UserProfile object of the user requested for insertion
     */
    private func insertResult(user: UserProfile) {
        
        // Update data source, then insert row
        searchResults.append(user)
        usersTableView.insertRows(at: [IndexPath(row: searchResults.count - 1, section: 0)], with: .none)
    }
    
    
    // MARK: Additional Functions
    /** Dismiss the keyboard from screen if currently displayed. */
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
}


// MARK: - Table View
extension NewConvoViewController: UITableViewDataSource, UITableViewDelegate {
    
    /** Sets the number of sections to display in the table view. */
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    /** Sets the number of rows to render for a given section in the table view. */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    
    /** Determines the content of the table view cell at specified index path. */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Populate table with results from lookup
        // Important: At this point in development, we are assuming only one search result can be found and displayed
        
        let cell = usersTableView.dequeueReusableCell(withIdentifier: "UserInfoCell", for: indexPath) as! UserInfoCell
        
        // Set cell info
        cell.displayImage.image = UIImage(named: "user_purple")
        cell.displayName.text = searchResults[indexPath.row].name
        cell.usernameLabel.text = "@" + searchResults[indexPath.row].username
        
        let uid = searchResults[indexPath.row].uid
        cell.uid = uid
        cell.username = searchResults[indexPath.row].username
        
        // Download image into cell using DatabaseController (this facilitates automatic caching)
        let path = "displayPictures/\(uid)/\(uid).JPG"
        databaseManager.downloadImage(into: cell.displayImage, from: path, completion: { error in
            
            if let error = error {
                print("AtMe:: An error has occurred, but image data was detected. \(error)")
                return
            }
        })
        
        // TODO: In future update, move circle frame code into Cell class (also applies to ChatListViewController)
        // Give display picture a circular mask
        cell.displayImage.layer.masksToBounds = true;
        cell.displayImage.clipsToBounds = true
        cell.displayImage.layer.cornerRadius = cell.displayImage.frame.size.width / 2
        
        return cell
    }
    
    
    /** Called when a given row / index path is selected in the table view. */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! UserInfoCell
        
        // Retrieve uid of selected user, create conversation record in Firebase
        // This should only be done if a conversation does not already exist
        
        if let selectedUserUid = cell.uid, let selectedUserUsername = cell.username {
            
            // Create the conversation (or even reuse old existing one), then exit this view
            databaseManager.createConversationWith(user: selectedUserUsername, withID: selectedUserUid, completion: { success in
                
                // If successful, exit. If unsuccessful, present alert so user is informed of preexisting conversation
                if (success) {
                    self.navigationController?.popViewController(animated: true)
                    
                } else {
                    self.presentSimpleAlert(title: "Conversation already exists", message: Constants.Errors.conversationAlreadyExists, completion: nil)
                }
            })
            
        } else { presentSimpleAlert(title: "Error creating conversation", message: Constants.Errors.createConversationError, completion: nil) }
    }
}
