//
//  NewConvoViewController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-02-25.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import Firebase

class NewConvoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, AlertController {

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
        
        usersSearchBar.barTintColor = Constants.Colors.primaryDark
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
        
        // Set cell info
        cell.displayImage.image = UIImage(named: "user_purple")
        cell.displayName.text = searchResults[indexPath.row].name
        cell.usernameLabel.text = "@" + searchResults[indexPath.row].username
        
        let uid = searchResults[indexPath.row].uid
        cell.uid = uid
        cell.username = searchResults[indexPath.row].username
        
        // Download image into cell using DatabaseController (this facilitates automatic caching)
        let displayPictureRef = self.userDisplayPictureRef.child("\(uid)/\(uid).JPG")
        DatabaseController.downloadImage(into: cell.displayImage, from: displayPictureRef, completion: { error in
            
            if let error = error {
                print("At.ME:: An error has occurred, but image data was detected. \(error)")
                return
            }
        })
        
        // FIXME: Move circle frame code into Cell class (also applies to ChatListViewController)
        // Give display picture a circular mask
        cell.displayImage.layer.masksToBounds = true;
        cell.displayImage.clipsToBounds = true
        cell.displayImage.layer.cornerRadius = cell.displayImage.frame.size.width / 2
        
        return cell
    }
    
    // ==========================================
    // ==========================================
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! UserInfoCell
        
        
        // Retrieve uid of selected user, create conversation record in Firebase
        // This should only be done if a conversation does not already exist
        
        if let selectedUserUid = cell.uid, let selectedUserUsername = cell.username {
        
            DatabaseController.doesConversationExistWith(username: selectedUserUsername, completion: { exists in
                
                if (!exists) {
                    
                    // Generate unique conversation identifier
                    let convoID = self.conversationsRef.childByAutoId().key
                    
                    // Establish the database record for this conversation
                    self.userInformationRef.observeSingleEvent(of: DataEventType.value, with: { snapshot in
                        
                        // Store list of member uid's and their notificationIDs in conversation for quick lookup
                        let selectedUserNotificationID = snapshot.childSnapshot(forPath: "\(selectedUserUid)/notificationID").value as? String
                        let members = [UserState.currentUser.uid: UserState.currentUser.notificationID, selectedUserUid: selectedUserNotificationID!]
                        let lastSeen = [UserState.currentUser.uid: Date().timeIntervalSince1970, selectedUserUid: Date().timeIntervalSinceNow]
                        
                        self.conversationsRef.child("\(convoID)/creator").setValue(UserState.currentUser.username)
                        self.conversationsRef.child("\(convoID)/activeMembers").setValue(members)
                        self.conversationsRef.child("\(convoID)/lastSeen").setValue(lastSeen)
                        
                        // For both users separately, record the convoId in a record identified by other user's username
                        self.userConversationListRef.child(UserState.currentUser.uid).child(selectedUserUsername).setValue(convoID)
                        self.userConversationListRef.child(selectedUserUid).child(UserState.currentUser.username).setValue(convoID)
                    })
                    
                    // Dismiss view now that conversation has been created
                    self.dismiss(animated: true, completion: nil)
                
                    
                } else {
                    self.presentSimpleAlert(title: "Conversation Already Exists", message: Constants.Errors.conversationAlreadyExists, completion: nil)
                }
            })
        }
    }
    
    
    // MARK: Search Bar + Results
    // ==========================================
    // ==========================================
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        clearResults()
        guard let text = searchBar.text else { return }
        
        // Look inside registeredUsernames, determine if username is registered or not
        // Extract the uid recorded here if found, then use it to find user details
        
        // Must make end query upper bound include the searched text
        // We accomplish this by adding a letter, eg. bill < billz and is thus included in query range below
        
        var end = text.characters.dropLast(0)
        end.append("z")
        
        // Find all usernames containing search text
        registeredUsernamesRef.queryOrderedByKey().queryStarting(atValue: text).queryEnding(atValue: String(end)).queryLimited(toFirst: 20).observeSingleEvent(of: DataEventType.value, with: { snapshot in
            
            // Parse results as dictionary of username/uid pairs
            if var results = snapshot.value as? [String : String] {
                
                // Never allow option to start conversation with yourself!!
                results.removeValue(forKey: UserState.currentUser.username)
                
                // One by one, obtain details of each user, and insert the result into table with more info
                self.findDetailsForUsers(results: results, completion: { user in
                    self.insertResult(user: user)
                })
            }
        })
    }
    
    // ==========================================
    // ==========================================
    private func clearResults() {
        
        searchResults.removeAll()
        usersTableView.reloadData()
    }
    
    // ==========================================
    // ==========================================
    private func insertResult(user: UserProfile) {
        
        // Update data source, then insert row
        searchResults.append(user)
        usersTableView.insertRows(at: [IndexPath(row: searchResults.count - 1, section: 0)], with: .none)
    }
    
    
    // MARK: Database Retrieval Functions
    // ==========================================
    // ==========================================
    private func findDetailsForUsers(results: [String : String], completion: @escaping (UserProfile) -> Void) {
        
        // For each result found, observe the user's full name and pass back as a UserProfile object
        // Using this UserProfile, the table view can be updated with info by the caller!
        
        for (username, uid) in results {
         
            userInformationRef.child(uid).observeSingleEvent(of: DataEventType.value, with: { snapshot in
            
                // Read first and last name, pass back to caller using callback when done
                let first = snapshot.childSnapshot(forPath: "firstName").value as? String ?? ""
                let last = snapshot.childSnapshot(forPath: "lastName").value as? String ?? ""
                    
                let user = UserProfile(name: first + " " + last, uid: uid, username: username)
                completion(user)
            })
        }
    }
    
    // MARK: Additional Functions
    // ==========================================
    // ==========================================
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
}
