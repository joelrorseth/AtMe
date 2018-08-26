//
//  DatabaseController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-05-21.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import Firebase
import Kingfisher

class DatabaseController {
  
  var userManager: UserManager = FirebaseUserManager.shared
  
  // MARK: - Properties
  var userConversationListRef: DatabaseReference = Database.database().reference().child("userConversationList")
  var userInactiveConversationsRef: DatabaseReference = Database.database().reference().child("userInactiveConversations")
  var conversationsRef: DatabaseReference = Database.database().reference().child("conversations")
  var userInformationRef: DatabaseReference = Database.database().reference().child("userInformation")
  
  
  // MARK: - Image Management
  /**
   Downloads an image (from a location in the database) into a specified UIImageView.
   - parameters:
   - destination: The UIImageView that, if successful, will be given the downloaded image
   - location: A path to the image being search for, relative to the root of the storage database
   - completion: Function called when finished, passing back an optional Error object if unsuccessful
   - error: An Error object created and returned if unsuccesful for any reason
   */
  public func downloadImage(into destination: UIImageView, from location: String, completion: @escaping (Error?)->()){
    let store = Storage.storage().reference(withPath: location)
    
    // Check for image saved in cache, load image from disk if possible
    // If it is, proceed with extracting it from cache instead
    if (ImageCache.default.imageCachedType(forKey: store.fullPath).cached) {
      
      ImageCache.default.retrieveImage(forKey: store.fullPath, options: nil) { (image, cacheType) in
        if let image = image {
          destination.image = image
        }
        
        completion(nil)
      }
      
    } else {
      
      // Otherwise, asynchronously download the file data stored at location and store it for later
      store.downloadURL(completion: { (url, error) in
        guard let url = url else { print("Error: Image download url was nil"); return }
        
        print("Image was not found in cache, downloading and caching now...")
        destination.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageUrl) in
          ImageCache.default.store(destination.image!, forKey: store.fullPath)
        })
        
        completion(error)
      })
    }
  }
  
  
  /**
   Uploads an image (in the form of a Data object) to a specified location in the database.
   - parameters:
   - data: The Data object holding the image information to store in the database
   - location: A path for the image data to be saved to, relative to the root of the storage database
   - completion: Function called when finished, passing back an optional Error object when unsuccessful
   - error: An Error object created and returned if unsuccesful for any reason
   */
  public func uploadImage(data: Data, to location: String, completion: @escaping (Error?)->()) {
    var localError: Error?
    let store = Storage.storage().reference(withPath: location)
    
    // Use put() to upload photo using a Data object
    store.putData(data, metadata: nil) { (metadata, error) in
      
      if let error = error { localError = error }
      completion(localError)
    }
  }
  
  
  /**
   Redownloads an image (from a location in the database) into a specified UIImageView. This will clear
   the original image from the cache and reload the image view directly.
   - parameters:
   - destination: The UIImageView that, if successful, will be given the downloaded image
   - location: A path to the image being reloaded, relative to the root of the storage database
   - completion: Function called when finished, passing back an optional Error object if unsuccessful
   - error: An Error object created and returned if unsuccesful for any reason
   */
  public func reloadImage(into destination: UIImageView, from location: String, completion: @escaping (Error?)->()) {
    
    // Convert location to Firebase storage path, remove from cache
    //let store = Storage.storage().reference(withPath: location)
    ImageCache.default.removeImage(forKey: location)
    
    // Redownload the image into cache and the provided image view using another method
    downloadImage(into: destination, from: location, completion: { error in
      completion(error)
    })
  }
  
  
  /** Clear all images currently cached by the database on disk or memory. */
  public func clearCachedImages() {
    
    // Clear memory cache right away.
    ImageCache.default.clearMemoryCache()
    
    // Clear disk cache. This is an async operation.
    ImageCache.default.clearDiskCache()
    
    // Clean expired or size exceeded disk cache. This is an async operation.
    ImageCache.default.cleanExpiredDiskCache()
    
    print("Image cache cleared from disk and memory")
    ImageCache.default.calculateDiskCacheSize { (size) in print("Used disk size by bytes: \(size)") }
  }
  
  
  // MARK: - Conversation Management
  /**
   If possible (and permitted), rejoin a specified user into given conversation with the **current user**.
   - parameters:
   - convoID: The convoID of the conversation to rejoin.
   - uid: The uid of the user whom will rejoin the conversation on his end.
   - username: The username of the user whom will rejoin the conversation on his end.
   - completion: A completion callback called when the function successfully or unsuccessfully terminates.
   - success: A boolean which is true if conversation was rejoined
   */
  public func attemptRejoinIntoConversation(convoID: String, uid: String, username: String, completion: @escaping (Bool) -> ()) {
    
    self.userManager.userOrCurrentUserHasBlocked(uid: uid, username: username, completion: { blocked in
      print("Attempting to rejoin, convo blocked? <\(blocked)>")
      // TODO: Possibly return custom error to discern if user was blocked?
      if blocked { completion(false); return }
      
      self.reactivateConversationFor(user: uid, username: username, with: UserState.currentUser.username, convoID: convoID, completion: { completed in
        completion(completed)
      })
    })
  }
  
  
  /**
   If possible, change a user's conversation with somebody from inactive to active status. If successful, this will move
   the conversation record from userConversationList to userInactiveConversations, and move the user from inactiveMembers
   to activeMembers in the actual convo record.
   - parameters:
   - uid: The uid of the user whose record of this conversation is to be reactivated.
   - username: The username of the user whose record of this conversation is to be reactivated.
   - otherUsername: The username of the user whom the conversation is with.
   - convoID: The convoID of the conversation to reactivate.
   - completion: A callback invoked if and when the operation was completed.
   - completed: A boolean which is true if the move was successful.
   */
  private func reactivateConversationFor(user uid: String, username: String, with otherUsername: String, convoID: String, completion: @escaping (Bool) -> ()) {
    
    // Observe inactive conversations for the specified user
    // Store handle for use inside closure, which will remove observer after closure executes
    var handle: UInt = 0
    handle = userInactiveConversationsRef.child(uid).observe(DataEventType.value, with: { snapshot in
      
      // Extract specified user's inactive conversations as (username: convoID) pairs
      if let inactiveConvos = (snapshot.value as? [String : String]) {
        //print(inactiveConvos)
        
        if inactiveConvos[otherUsername] == convoID {
          
          // Move the record of conversation from inactive to active convo list
          self.userInactiveConversationsRef.child(uid).child(otherUsername).removeValue()
          self.userConversationListRef.child(uid).child(otherUsername).setValue(convoID)
          
          // Re-establish current user as an active member
          self.conversationsRef.child("\(convoID)/inactiveMembers/\(uid)").removeValue()
          self.conversationsRef.child("\(convoID)/activeMembers/\(uid)").setValue(username)
          
          completion(true)
          self.userInactiveConversationsRef.child(uid).removeObserver(withHandle: handle)
        }
      }
    })
  }
  
  
  /**
   Determine if an active conversation record currently exists between the current user and specified user, and return convoID if so.
   - parameters:
   - username: Username to check for existence of conversation with current user
   - completion: Callback called when search has concluded
   - exists: A boolean which is true if current user is in an active conversation with the user
   */
  public func doesActiveConversationExistWith(username: String, completion: @escaping (Bool) -> Void) {
    
    // Query the user's active conversation record for the current user('s uid)
    // If query returns non-nil, the query found a conversation record with other user
    
    userConversationListRef.child(UserState.currentUser.uid).queryOrderedByKey()
      .queryEqual(toValue: username).observeSingleEvent(of: DataEventType.value, with: { snapshot in
        
        // Extract the convoID of any existing conversation - there should only ever be one
        if snapshot.hasChildren() { completion(true) }
        else { completion(false) }
      })
  }
  
  
  /**
   Determine if current user has inactive conversation record with a specified user, and return convoID if so.
   - parameters:
   - username: Username to check for existence of conversation with current user
   - completion: Callback called at search end, passing back an optional string with convoID
   - convoID: An optional String holding the conversation ID of the found conversation, if it exists
   */
  public func findInactiveConversationWith(username: String, completion: @escaping (String?) -> Void) {
    
    // Check inactive conversations record, see if conversation with username ever existed
    userInactiveConversationsRef.child(UserState.currentUser.uid).observeSingleEvent(of: DataEventType.value, with: { snapshot in
      
      // The only way this seemed to work was downloading the whole list of convos, check manually
      if let conversations = snapshot.value as? [String : String] {
        
        if let inactiveConvo = conversations[username] {
          completion(inactiveConvo)
          return
        }
      }
      
      completion(nil)
    })
  }
  
  // TODO: Refactor for future update
  /**
   Attempts to create a conversation between current user and a given user, or rejoins an existing conversation with user if active.
   This method is duplicate safe, and checks for inactive and currently active conversations to avoid creating multiple conversations.
   - parameters:
   - username: The username of the user to create the conversation with
   - uid: The user id of the user to create the conversation with
   - completion: A blank callback called when conversation has been created
   - success: A boolean which is false if the conversation could not be created
   */
  public func createConversationWith(user username: String, withID uid: String, completion: @escaping (Bool)->()) {
    
    
    // IMPORTANT NOTE: The app logic assumes that one (and only one) conersation will ever exist between two
    // users. We maintain a record of active and inactive conversations, observe only the active
    // ones, and transfer a conversation record back and forth when deleted or (re)created by user.
    
    userManager.userOrCurrentUserHasBlocked(uid: uid, username: username, completion: { blocked in
      
      // Prevent
      if blocked { completion(false); return }
      
      // Now that we checked if user is blocked, check if active convo exists for current user
      // In regards to note above, we only allow one convo record between users
      // The actual convo stays in place, but userConversationList tracks active members
      
      self.doesActiveConversationExistWith(username: username, completion: { exists in
        
        // If conversation exists, just exit gracefully and do absolutely nothing
        if (exists) { print("Error: Active conversation already exists"); completion(false); return }
        
        self.findInactiveConversationWith(username: username, completion: { convoID in
          
          // If a conversation still exists with this user, just join into the existing one
          // Re-establish the current user as an active member (eg. inactive --> active)
          if let convoID = convoID {
            print("Reactivating old conversation: \(convoID)")
            
            // Delete this conversation from inactive convo record, add it to the active convo record
            // This is important, since the conversation list obserever in ChatListViewController will find and load this
            
            self.userInactiveConversationsRef.child(UserState.currentUser.uid).child(username).removeValue()
            self.userConversationListRef.child(UserState.currentUser.uid).child(username).setValue(convoID)
            
            // Establish current user as an active member
            self.conversationsRef.child("\(convoID)/inactiveMembers/\(UserState.currentUser.uid)").removeValue()
            self.conversationsRef.child("\(convoID)/activeMembers/\(UserState.currentUser.uid)").setValue(UserState.currentUser.username)
            
            completion(true)
          }
            
            
            // Otherwise, a new conversation is generated and recorded into database
          else {
            
            // Generate unique conversation identifier
            let convoID = self.conversationsRef.childByAutoId().key
            print("Generating a new conversation: \(convoID)")
            
            // Establish the database record for this conversation
            self.userInformationRef.observeSingleEvent(of: DataEventType.value, with: { snapshot in
              
              // Store list of each member's uid and username for quick lookup
              // More importantly, this is stored to track who is active and should receive push notifications
              
              let members = [UserState.currentUser.uid: UserState.currentUser.username, uid: username]
              let lastSeen = [UserState.currentUser.uid: Date().timeIntervalSince1970, uid: Date().timeIntervalSinceNow]
              
              //let selectedUserNotificationID = snapshot.childSnapshot(forPath: "\(uid)/notificationID").value as? String
              //let members = [UserState.currentUser.uid: UserState.currentUser.notificationID, uid: selectedUserNotificationID!]
              
              self.conversationsRef.child("\(convoID)/creator").setValue(UserState.currentUser.username)
              self.conversationsRef.child("\(convoID)/activeMembers").setValue(members)
              self.conversationsRef.child("\(convoID)/lastSeen").setValue(lastSeen)
              
              // For both users separately, record the convoId in a record identified by other user's username
              self.userConversationListRef.child(UserState.currentUser.uid).child(username).setValue(convoID)
              self.userConversationListRef.child(uid).child(UserState.currentUser.username).setValue(convoID)
              
              completion(true)
            })
          }
        })
      })
    })
  }
  
  
  /**
   Retrieve details for current user from the database. User must be authorized already.
   - parameters:
   - user: The current user, which should be authorized at this point
   - completion:Callback that fires when function has finished
   - configured: A boolean representing if the current user object could be configured (required)
   */
  public func notificationIDForUser(with uid: String, completion: @escaping (String?) -> ()) {
    
    userInformationRef.child("\(uid)/notificationID").observeSingleEvent(of: DataEventType.value, with: { snapshot in
      
      // Pass notification id to completion handler, will pass nil if empty
      completion( snapshot.value as? String )
    })
  }
  
  
  /** Unsubscribe the specified user from push notifications by removing their notification ID from the database. */
  public func unsubscribeUserFromNotifications(uid: String) {
    
    // Remove the user's notification ID from the database (stop receiving push notifications)
    // This is the only location that a user's notification ID is stored
    
    userInformationRef.child("\(uid)/notificationID").removeValue()
  }
  
  
  /**
   Removes the current user from a given conversation, thus archiving it and making it inactive.
   - parameters:
   - convoID: The conversation ID of the conversation the current user requests to leave
   - username: The username of the user to with whom the conversation was with
   - completion: A blank callback called when current user has been removed from conversation
   */
  public func leaveConversation(convoID: String, with username: String, completion: @escaping ()->()) {
    
    let currentUid = UserState.currentUser.uid
    let currentUsername = UserState.currentUser.username
    
    // Move record from active to inactive user record
    userConversationListRef.child(currentUid).child(username).removeValue()
    userInactiveConversationsRef.child(currentUid).child(username).setValue(convoID)
    
    // Remove record of current user from conversation active members
    conversationsRef.child("\(convoID)/activeMembers/\(currentUid)").removeValue()
    conversationsRef.child("\(convoID)/inactiveMembers/\(currentUid)").setValue(currentUsername)
    
    completion()
  }
}
