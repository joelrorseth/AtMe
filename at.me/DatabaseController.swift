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
    
    // ==========================================
    // ==========================================
    public static func downloadImage(into destination: UIImageView, from location: FIRStorageReference, completion: @escaping (Error?)->()){

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
    public static func uploadImage(data: Data, to location: FIRStorageReference, completion: @escaping (Error?)->()) {
        var localError: Error?
        
        // Use put() to upload photo using a Data object
        location.put(data, metadata: nil) { (metadata, error) in
            
            if let error = error { localError = error }
            completion(localError)
        }
    }
}
