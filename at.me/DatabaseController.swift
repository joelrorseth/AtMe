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
    
    // FIXME: Refactor this class and NotificationsController to be non static
    private var userConversationListRef: DatabaseReference = Database.database().reference().child("userConversationList")
    
    // ==========================================
    // ==========================================
    public func downloadImage(into destination: UIImageView, from location: StorageReference, completion: @escaping (Error?)->()){

        if (ImageCache.default.isImageCached(forKey: location.fullPath).cached) {
            
            // Check for image saved in cache, load image from disk if possible
            ImageCache.default.retrieveImage(forKey: location.fullPath, options: nil) { (image, cacheType) in
                if let image = image {
                    print("AT.ME:: Image was retrieved from cache at: \(location.fullPath)")
                    destination.image = image
                }
                
                completion(nil)
            }
            
        } else {
            
            // Otherwise, asynchronously download the file data stored at location and store it for later
            location.downloadURL(completion: { (url, error) in
                guard let url = url else { return }
                
                print("AT.ME:: Image was not found in cache, downloading and caching now...")
                destination.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: { _ in
                    ImageCache.default.store(destination.image!, forKey: location.fullPath)
                })
                
                completion(error)
            })
        }
    }
    
    // ==========================================
    // ==========================================
    public func uploadImage(data: Data, to location: StorageReference, completion: @escaping (Error?)->()) {
        var localError: Error?
        
        // Use put() to upload photo using a Data object
        location.putData(data, metadata: nil) { (metadata, error) in
            
            if let error = error { localError = error }
            completion(localError)
        }
    }
    
    // ==========================================
    // ==========================================
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
    
    /**
     Determines if a conversation record currently exists between the current user and specified user
     - parameters:
        - username: Username to check for existence of conversation with current user
        - completion: Asynchronously return boolean value representing conversation existence
            - exists: A boolean which is true if current user has existing conversation record with specified user
     */
    public func doesConversationExistWith(username: String, completion: @escaping (Bool) -> Void) {
        
        
        // Query conversation record for the current user('s uid)
        // If query returns non-nil, the query found a conversation record with other user
        
        userConversationListRef.child(UserState.currentUser.uid).queryOrderedByKey().queryEqual(toValue: username).observeSingleEvent(of: DataEventType.value, with: { snapshot in
            
            if (snapshot.hasChildren()) { completion(true) }
            else { completion(false) }
        })
    }
}
