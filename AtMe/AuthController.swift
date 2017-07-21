//
//  AuthController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-06-25.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import Firebase
import FirebaseCore

class AuthController {
    
    // Firebase References
    private lazy var userInformationRef: DatabaseReference = Database.database().reference().child("userInformation")
    private lazy var registeredUsernamesRef: DatabaseReference = Database.database().reference().child("registeredUsernames")
    
    
    /**
     Asynchronously attempts to create an @Me account
     - parameters:
        - displayPicture: Firebase storage url for the users display picture (if set)
        - email: Email address
        - username: Username
        - firstName: First name
        - lastName: Last name
        - password: Password
        - completion: Callback that returns an Error object back to caller at completion
            - error: An Error object returned from the Auth Controller
            - uid: The UID assigned to the user upon successful account creation
     */
    public func createAccount(email: String, firstName: String, lastName: String,
                              password: String, completion: @escaping ((Error?, String?) -> ()) ) {
    
        // If the username already exists, avoid creating user
        // Look this up asynchronously in Firebase, call completion callback when finished regardless of findings
        // Note: The must be done inside the observe block to properly update synchronously

        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
            
            // Present backend errors to user when @Me does not catch them
            if let error = error {
                completion(error, user?.uid)
                return
            }
            
            // Add entry to usernames index and user info record
            self.userInformationRef.child((user?.uid)!).setValue(
                ["email" : email,
                 "firstName" : firstName,
                 "lastName" : lastName,
                 "notificationID": NotificationsController.currentDeviceNotificationID() ?? nil]
            )
            
            completion(error, user?.uid)
        })
    }
    
    
    /**
     Asynchronously attempts to sign in to an @Me account
     - parameters:
        - email: Email address
        - password: Password
        - completion: Callback that returns an Error object back to caller at completion
            - error: An Error object returned from the Auth Controller
            - configured: A boolean representing if the current user object could be configured (required)
     */
    public func signIn(email: String, password: String, completion: @escaping ((Error?, Bool) -> ()) ) {
        
        // Let the auth object sign in the user with given credentials
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            
            // Call completion block with resulting error (hopefully nil when successful)
            if let error = error { completion(error, false); return }
            guard let user = user else { return }
            
            // Call database function to retrieve information about current user, and set the static current user object
            // The completion callback returns a bool indicating success, so return that value in this completion callback too!
            self.establishCurrentUser(user: user, completion: { configured in
                completion(error, configured)
            })
        }
    }
    
    
    /**
     Asynchronously determines if a given username has been taken in the current database
     - parameters:
        - username: Username to search for
        - completion: Callback that fires when function has finished
            - found: True if username was found in database, false otherwise
     */
    public func usernameExists(username: String, completion: @escaping (Bool) -> ()) {
        
        registeredUsernamesRef.observeSingleEvent(of: DataEventType.value, with: { snapshot in
            
            if (snapshot.hasChild(username)) { completion(true) }
            else { completion(false) }
        })
    }
    
    
    /**
     Retrieve details for current user from the database. User must be authorized already.
     - parameters:
        - user: The current user, which should be authorized at this point
        - completion:Callback that fires when function has finished
            - configured: A boolean representing if the current user object could be configured (required)
     */
    public func establishCurrentUser(user: User, completion: @escaping (Bool) -> ()) {
        
        // TODO: Change to take snapshot of only this user's info, use child(uid)
        // Look up information about the User, set the UserState.currentUser object properties
        self.userInformationRef.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            
            // Important: Must be able to set ALL PROPERTIES of current user, else do not authorize!
            guard let email = user.email,
                let username = snapshot.childSnapshot(forPath: "\(user.uid)/username").value as? String,
                let first = snapshot.childSnapshot(forPath: "\(user.uid)/firstName").value as? String,
                let last = snapshot.childSnapshot(forPath: "\(user.uid)/lastName").value as? String,
                let notificationID = snapshot.childSnapshot(forPath: "\(user.uid)/notificationID").value as? String
                else { completion(false); return }
            print("================ stored \(notificationID)")
            if let deviceNotificationID = NotificationsController.currentDeviceNotificationID() {
                if deviceNotificationID != notificationID {
                    print("================ stored \(notificationID), now \(deviceNotificationID) =================")
                    // If the user has signed in on a new device, the notification ID may have changed
                    // This needs to be checked and updated at every sign in, update database if changed
                    
                    print("New device detected, updating the current user's notification ID")
                    self.userInformationRef.child("\(user.uid)/notificationID").setValue(deviceNotificationID)
                }
            }
            
            // Set all properties of currentUser now that they have been unwrapped if needed
            UserState.currentUser.displayPicture = "\(user.uid)/\(user.uid).JPG"
            UserState.currentUser.email = email
            UserState.currentUser.name = first + " " + last
            UserState.currentUser.notificationID = notificationID
            UserState.currentUser.uid = user.uid
            UserState.currentUser.username = username
            
            completion(true)
        })
    }
    
    
    
    /**
     Writes a user's username into their information record and usernames registry in the database
     - parameters:
     - username: Username chosen by the current user
     - completion: Callback that is called upon successful completion
     */
    public func setUsername(username: String, completion: (() -> ())) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Set current user, update username field in userInformation and registeredUsernames
        UserState.currentUser.username = username
        userInformationRef.child("\(uid)/username").setValue(username)
        registeredUsernamesRef.child(username).setValue(uid)
        completion()
    }
    
    
    /**
     Writes the database storage path of an uploaded display picture to the current users information record
     - parameters:
     - path: The path where the display picture has been successfully uploaded to
     */
    public func setDisplayPicture(path: String) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        UserState.currentUser.displayPicture = path
        userInformationRef.child("\(uid)/displayPicture").setValue(path)
    }
}
