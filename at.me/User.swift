//
//  User.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-03-12.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import Foundation

public class User {
    
    var username: String
    var uid: String

    init(username: String, uid: String) {
        self.username = username
        self.uid = uid
    }
}
