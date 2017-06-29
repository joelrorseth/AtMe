//
//  UserProfile.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-03-12.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import Foundation

public class UserProfile {
    
    var name: String
    var uid: String
    var username: String
    
    // Note: displayPicture should be used as little as possible and phased out
    // All display picture URLs can be composed with the user's UID, thus elimintating need to store this
    //var displayPicture: String

    init(name: String, uid: String, username: String) {
        self.name = name
        self.uid = uid
        self.username = username
    }
}
