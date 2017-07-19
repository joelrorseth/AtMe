//
//  DatabaseController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-05-21.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import Firebase
import Kingfisher

class DatabaseController {
    
    private lazy var userConversationListRef: DatabaseReference = Database.database().reference().child("userConversationList")
    private lazy var userInactiveConversationsRef: DatabaseReference = Database.database().reference().child("userInactiveConversations")
    private lazy var conversationsRef: DatabaseReference = Database.database().reference().child("conversations")
    private lazy var userInformationRef: DatabaseReference = Database.database().reference().child("userInformation")
    
    
    // MARK: Image Management
    /**
     Downloads an image (from a location in the database) into a specified UIImageView.
     - parameters:
        - destination: The UIImageView that, if successful, will be given the downloaded image
        - location: A path to the image being search for, relative to the root of the storage database
        - completion: Function called when finished, passing back an optional Error object when unsuccessful
            - error: An Error object created and returned if unsuccesful for any reason
     */
    public func downloadImage(into destination: UIImageView, from location: String, completion: @escaping (Error?)->()){
        let store = Storage.storage().reference(withPath: location)
        
        // Check for image saved in cache, load image from disk if possible
        // If it is, proceed with extracting it from cache instead
        if (ImageCache.default.isImageCached(forKey: store.fullPath).cached) {
        
            ImageCache.default.retrieveImage(forKey: store.fullPath, options: nil) { (image, cacheType) in
                if let image = image {
                    print("Image was retrieved from cache at: \(store.fullPath)")
                    destination.image = image
                }
                
                completion(nil)
            }
            
        } else {
            
            // Otherwise, asynchronously download the file data stored at location and store it for later
            store.downloadURL(completion: { (url, error) in
                guard let url = url else { return }
                
                print("Image was not found in cache, downloading and caching now...")
                destination.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: { _ in
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
    
    
    // MARK: Conversation Management
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
     Determine if an inactive conversation record currently exists between the current user and specified user, and return convoID if so.
     - parameters:
        - username: Username to check for existence of conversation with current user
        - completion: Callback called at search end, passing back an optional string with convoID
            - convoID: An optional String holding the conversation ID of the found conversation, if it exists
     */
    public func findInactiveConversationWith(username: String, completion: @escaping (String?) -> Void) {
        
        userInactiveConversationsRef.child(UserState.currentUser.uid).queryOrderedByKey()
            .queryEqual(toValue: username).observeSingleEvent(of: DataEventType.value, with: { snapshot in
            
            // Extract the convoID of any existing conversation - there should only ever be one
            if (snapshot.hasChildren()) {
                if let conversation = snapshot.children.allObjects[0] as? DataSnapshot {
                    
                    // Safely unwrap conversation ID, pass it back to completion handler
                    guard let convoID = conversation.value as? String else { completion(nil); return }
                    completion(convoID)
                }
            
            } else { completion(nil) }
        })
    }
    
    
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
        
        
        // Note: The app logic assumes that one (and only one) conersation will ever exist between two
        // users. We maintain a record of active and inactive conversations, observe only the active
        // ones, and transfer a conversation record back and forth when deleted or (re)created by user.
        

        doesActiveConversationExistWith(username: username, completion: { exists in
            
            // If conversation exists, just exit gracefully and do absolutely nothing
            if (exists) { print("Error: Active conversation already exists"); completion(false); return }
            
            self.findInactiveConversationWith(username: username, completion: { convoID in
                
                // If a conversation still exists with this user, just join into the existing one
                if let convoID = convoID {
                    
                    // Delete this conversation from inactive convo record, add it to the active convo record
                    // This is important, since the conversation list obserever in ChatListViewController will find and load this
                    
                    self.userInactiveConversationsRef.child(UserState.currentUser.uid).child(username).removeValue()
                    self.userConversationListRef.child(UserState.currentUser.uid).child(username).setValue(convoID)
                    
                    // Establish current user as an active member
                    self.conversationsRef.child("\(convoID)/activeMembers/\(UserState.currentUser.uid)").setValue(UserState.currentUser.notificationID)
                    
                    completion(true)
                }
                    
                    
                // Otherwise, a new conversation is generated and recorded into database
                else {
                    
                    // Generate unique conversation identifier
                    let convoID = self.conversationsRef.childByAutoId().key
                    
                    // Establish the database record for this conversation
                    self.userInformationRef.observeSingleEvent(of: DataEventType.value, with: { snapshot in
                        
                        // Store list of member uid's and their notificationIDs in conversation for quick lookup
                        let selectedUserNotificationID = snapshot.childSnapshot(forPath: "\(uid)/notificationID").value as? String
                        let members = [UserState.currentUser.uid: UserState.currentUser.notificationID, uid: selectedUserNotificationID!]
                        let lastSeen = [UserState.currentUser.uid: Date().timeIntervalSince1970, uid: Date().timeIntervalSinceNow]
                        
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
    }
    
    
    /**
     Removes the current user from a given conversation, thus archiving it and making it inactive.
     - parameters:
        - convoID: The conversation ID of the conversation the current user requests to leave
        - username: The username of the user to with whom the conversation was with
        - completion: A blank callback called when current user has been removed from conversation
     */
    public func leaveConversation(convoID: String, with username: String, completion: @escaping ()->()) {
        
        // Move record from active to inactive user record
        userConversationListRef.child(UserState.currentUser.uid).child(username).removeValue()
        userInactiveConversationsRef.child(UserState.currentUser.uid).child(username).setValue(convoID)
        
        // Remove record of current user from conversation active members
        conversationsRef.child("\(convoID)/activeMembers/\(UserState.currentUser.uid)").removeValue()
        
        completion()
    }
}
