//
//  UserProfile.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-03-12.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import Foundation

public class UserProfile {
    
    var displayName: String
    var uid: String
    var username: String

    init(displayName: String, uid: String, username: String) {
        self.displayName = displayName
        self.uid = uid
        self.username = username
    }
}
