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

    // Firebase references
    private lazy var registeredUsernamesRef: DatabaseReference = Database.database().reference().child("registeredUsernames")
    private lazy var userConversationListRef: DatabaseReference = Database.database().reference().child("userConversationList")
    private lazy var userInformationRef: DatabaseReference = Database.database().reference().child("userInformation")
    private lazy var conversationsRef: DatabaseReference = Database.database().reference().child("conversations")
    lazy var userDisplayPictureRef: StorageReference = Storage.storage().reference().child("displayPictures")
    
    @IBOutlet weak var usersSearchBar: UISearchBar!
    @IBOutlet weak var usersTableView: UITableView!
    
    var searchResults: [UserProfile] = []
    
    // ==========================================
    // ==========================================
    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: View Lifecycle
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        
        // Set up search bar, ask keyboard to appear when view is loaded
        self.usersSearchBar.delegate = self
        self.usersSearchBar.becomeFirstResponder()
        //self.usersSearchBar.barTintColor = Constants.Colors.primaryColor
        
        // Set translucent navigation bar with color
        //let image = UIImage.imageFromColor(color: Constants.Colors.primaryColor)
        //usersSearchBar.backgroundImage = UIImage()
        usersSearchBar.barTintColor = Constants.Colors.primaryColor
        usersSearchBar.isTranslucent = false
        
        self.title = "New Conversation"
        //self.navigationController?.title
        //self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        
        // Little trick to hide empty cells from table view
        // TODO: Add suggestions to start a convo instead of a blank screen
        self.usersTableView.tableFooterView = UIView()
        
        // Add gesture recognizer to handle tapping outside of keyboard
        let dismissKeyboardTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissKeyboardTap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(dismissKeyboardTap)
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
        return CGFloat(80)
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
        // Important: At this point in development, we are assuming only one search result can be found and displayed
        
        let cell = usersTableView.dequeueReusableCell(withIdentifier: "UserInfoCell", for: indexPath) as! UserInfoCell
        
        cell.displayName.text = searchResults[0].name
        cell.usernameLabel.text = searchResults[0].username
        
        cell.uid = searchResults[0].uid
        cell.username = searchResults[0].username
        
        // Download image into cell using DatabaseController (this facilitates automatic caching)
        let displayPictureRef = self.userDisplayPictureRef.child("\(searchResults[0].uid)/\(searchResults[0].uid).JPG")
        DatabaseController.downloadImage(into: cell.displayImage, from: displayPictureRef, completion: { error in
            
            if let error = error {
                print("At.ME:: An error has occurred, but image data was detected. \(error)")
                return
            }
        })
        
        // FIXME: Move circle frame code into Cell class (also applies to ChatListViewController)
        // Give display picture a circular mask
        cell.displayImage.layer.masksToBounds = true;
        cell.displayImage.layer.cornerRadius = cell.displayImage.frame.width / 2
        
        return cell
    }
    
    // ==========================================
    // ==========================================
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! UserInfoCell
        print("AT.ME:: Creating conversation with user with username: \(cell.usernameLabel.text!)")
        
        // Retrieve uid of selected user, create conversation record in Firebase
        if let selectedUserUid = cell.uid, let selectedUserUsername = cell.username {
            
            // Generate unique conversation identifier
            let convoID = conversationsRef.childByAutoId().key
            
            // Establish the database record for this conversation
            userInformationRef.observe(DataEventType.value, with: { snapshot in
                
                // Store list of member uid's and their notificationIDs in conversation for quick lookup
                let selectedUserNotificationID = snapshot.childSnapshot(forPath: "\(selectedUserUid)/notificationID").value as? String
                let members = [UserState.currentUser.uid: UserState.currentUser.notificationID, selectedUserUid: selectedUserNotificationID!]
                let lastSeen = [UserState.currentUser.uid: Date().timeIntervalSince1970, selectedUserUid: Date().timeIntervalSinceNow]
                
                self.conversationsRef.child("\(convoID)/creator").setValue(UserState.currentUser.username)
                self.conversationsRef.child("\(convoID)/activeMembers").setValue(members)
                self.conversationsRef.child("\(convoID)/lastSeen").setValue(lastSeen)
                self.conversationsRef.child("\(convoID)/messagesCount").setValue(0)
                
                // For both users separately, record the convoId in a record identified by other user's username
                self.userConversationListRef.child(UserState.currentUser.uid).child(selectedUserUsername).setValue(convoID)
                self.userConversationListRef.child(selectedUserUid).child(UserState.currentUser.username).setValue(convoID)
            })
            
            
            // TODO: For now, just dismiss. Future update: dismiss then open up conversation
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    
    // MARK: Search Bar + Results
    // ==========================================
    // ==========================================
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        
        // Look inside registeredUsernames, determine if username is registered or not
        // Extract the uid recorded here if found, then use it to find user details
        
        self.registeredUsernamesRef.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            
            // If valid user is found in the search
            if (snapshot.hasChild(searchBar.text!)) {
                
                // The value of key (username) is the uid of that user!
                let uidFound = snapshot.childSnapshot(forPath: searchBar.text!).value as! String

                // Return a User object with details about user with id 'uidFound'
                // Completion block will initiate update in table view (results)
                
                self.findUserDetail(forUID: uidFound, completion: { users in
        
                    // Update results to show all users in array (just one for now)
                    self.updateResults(users: users)
                })
                
                
            } else {
                
                // Alert user that the user name specified was not found
                let ac = UIAlertController(title: "User Not Found", message: "Please enter another username", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(ac, animated: true) { self.usersSearchBar.becomeFirstResponder() }
            }
        })
    }
    
    // ==========================================
    // ==========================================
    private func updateResults(users: [UserProfile]) {
        
        // Begin updates to table view, delete the most recently found user if currently shown
        self.usersTableView.beginUpdates()
        
        if (self.searchResults.count != 0) {
            self.usersTableView.deleteRows(at: [IndexPath.init(row: self.searchResults.count - 1, section: 0)], with: .automatic)
        }
        
        // Update the data source, then insert the rows into the table view
        // Important: This will trigger CellForRow:AtIndex() using the data source to populate
        
        self.searchResults = users
        self.usersTableView.insertRows(at: [IndexPath.init(row: self.searchResults.count - 1, section: 0)], with: .automatic)
        
        self.usersTableView.endUpdates()
    }
    
    
    // MARK: Database Retrieval Functions
    // ==========================================
    // ==========================================
    private func findUserDetail(forUID uid: String, completion: @escaping ([UserProfile]) -> Void) {
        
        // Using userInformation record, lookup using 'uid' as key
        userInformationRef.child(uid).observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            
            // TODO: Bug causing crash (displayName)
            // Can't force unwrap snapshot
            
            var users: [UserProfile] = []
            
            let fullName = (snapshot.childSnapshot(forPath: "firstName").value as! String) +
                " " + (snapshot.childSnapshot(forPath: "lastName").value as! String)
            
            users.append(UserProfile(
                name: fullName,
                uid: uid,
                username: snapshot.childSnapshot(forPath: "username").value as! String
            ))
            
            // IMPORTANT: Initiate user specified callback (provided when called)
            // User object must be returned through completion callback to
            // allow observeSingleEvent() time to execute asynchronously!
            
            completion(users)
        })
    }
    
    // MARK: Additional Functions
    // ==========================================
    // ==========================================
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
}
