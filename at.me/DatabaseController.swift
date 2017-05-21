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
    public static func uploadLibraryImage(url: URL, to location: FIRStorageReference, completion: @escaping (Error?)->()) {
        var localError: Error?
        
        // Pull photo from device using URL, upload to database
        location.putFile(url, metadata: nil) { (metadata, error) in
            
            if let error = error { localError = error }
            completion(localError)
        }
    }
    
    // ==========================================
    // ==========================================
    public static func uploadCameraImage(data: Data, to location: FIRStorageReference, completion: @escaping (Error?)->()) {
        var localError: Error?
        
        // Use put() to upload photo using a Data object
        location.put(data, metadata: nil) { (metadata, error) in
            
            if let error = error { localError = error }
            completion(localError)
        }
    }
}
