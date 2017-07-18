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
    
    
    /** Clear all images currently cached by the database on disk or memory */
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
