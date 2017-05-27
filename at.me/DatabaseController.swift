//
//  DatabaseController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-05-21.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import Firebase

class DatabaseController {
    
    // ==========================================
    // ==========================================
    public static func downloadImage(from location: FIRStorageReference, completion: @escaping (Error?, UIImage?)->()){

        // Asynchronously download the file data stored at 'path' (display picture)
        location.data(withMaxSize: INT64_MAX, completion: { (data, error) in
            
            if let imageData = data {
                
                // Send callback with UIImage, which may return nil 
                completion(error, UIImage(data: imageData))
                
            } else { print("AT.ME:: Could not extract image data from Database") }
        })
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
