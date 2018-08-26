//
//  AuthController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-06-25.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import Firebase

// Protocol to inform delegates of auth events
protocol AuthenticationDelegate {
  func userDidSignOut()
}


class FirebaseAuthManager: AuthManager {
  
  static let shared = FirebaseAuthManager()
  lazy var databaseManager = DatabaseController()
  
  // MARK: - Properties
  var authenticationDelegate: AuthenticationDelegate?
  
  // Firebase References
  var userInformationRef: DatabaseReference = Database.database().reference().child("userInformation")
  var registeredUsernamesRef: DatabaseReference = Database.database().reference().child("registeredUsernames")
  var reportedUsersRecordRef: DatabaseReference = Database.database().reference().child("reportedUsersRecord")
  
  
  init() {
    
    print("+ Initializing an AuthController")
    print("userInformation, registeredUsernames and reportedUsers have set keepSynced=true")
    
    // Must keep these Firebase locations in sync to prevent stale offline data
    userInformationRef.keepSynced(true)
    registeredUsernamesRef.keepSynced(true)
    reportedUsersRecordRef.keepSynced(true)
  }
  
  
  // MARK: - Account Management
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
        completion(error, user?.user.uid)
        return
      }
      
      // Add entry to usernames index and user info record
      self.userInformationRef.child((user?.user.uid)!).setValue(
        ["email" : email,
         "firstName" : firstName,
         "lastName" : lastName,
         "notificationID": NotificationsController.currentDeviceNotificationID() ?? nil]
      )
      
      completion(error, user?.user.uid)
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
      self.establishCurrentUser(user: user.user, completion: { configured in
        completion(error, configured)
      })
    }
  }
  
  
  /** Take the appropriate steps to sign the user out of the application. */
  public func signOut() throws {
    do {
      try Auth.auth().signOut()
    } catch let error {
      throw error
    }
    authenticationDelegate?.userDidSignOut()
    databaseManager.clearCachedImages()
    databaseManager.unsubscribeUserFromNotifications(uid: UserState.currentUser.uid)
    UserState.resetCurrentUser()
  }
}
