//
//  AuthController.swift
//  at.me
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
     Attempt to create an @Me account
     - parameters:
        - email: Email address
        - username: Username
        - firstName: First name
        - lastName: Last name
        - password: Password
        - completion: Callback that returns an Error object back to caller at completion
            - error: An Error object returned from the Auth Controller
            - taken: A bool stating if the username was taken
     */
    public func createAccount(email: String, username: String, firstName: String,
                                     lastName: String, password: String, completion: @escaping ((Error?, Bool) -> ()) ) {
    
        // If the username already exists, avoid creating user
        // Look this up asynchronously in Firebase, call completion callback when finished regardless of findings
        // Note: The must be done inside the observe block to properly update synchronously
        
        registeredUsernamesRef.observeSingleEvent(of: DataEventType.value, with: { snapshot in
            if (!snapshot.hasChild(username)) {
                
                Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                    
                    // Present backend errors to user when @Me does not catch them
                    if let error = error {
                        completion(error, false)
                        return
                    }
                    
                    // Add entry to database with public user information
                    let userEntry = ["displayName" : username, "email" : email, "firstName" : firstName, "lastName" : lastName,
                                     "notificationID": NotificationsController.currentUserNotificationsID() ?? nil, "username" : username]
                    
                    // Add entry to usernames index and user info record
                    self.registeredUsernamesRef.child(username).setValue((user?.uid)!)
                    self.userInformationRef.child((user?.uid)!).setValue(userEntry)
                    
                    // Update any <FIRUser> properties maintained internally by Firebase
                    let changeRequest = user?.createProfileChangeRequest()
                    changeRequest?.displayName = username
                    
                    completion(error, false)
                })
                

            } else { completion(nil, true) } // Otherwise, set 'taken' to true
        })
    }
    
    
    
    /**
     Attempt to sign in to an @Me account
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
            
            self.userInformationRef.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
                
                // Important: Must be able to set ALL PROPERTIES of current user, else do not authorize!
                guard let email = user.email,
                    let username = snapshot.childSnapshot(forPath: "\(user.uid)/username").value as? String,
                    let first = snapshot.childSnapshot(forPath: "\(user.uid)/firstName").value as? String,
                    let last = snapshot.childSnapshot(forPath: "\(user.uid)/lastName").value as? String,
                    let notificationID = NotificationsController.currentUserNotificationsID()
                    else { completion(error, false); return }
                
                // Set all properties of currentUser now that they have been unwrapped if needed
                UserState.currentUser.displayPicture = "\(user.uid)/\(user.uid).JPG"
                UserState.currentUser.email = email
                UserState.currentUser.name = first + " " + last
                UserState.currentUser.notificationID = notificationID
                UserState.currentUser.uid = user.uid
                UserState.currentUser.username = username
                
                completion(error, true)
            })
        }
    }
}
