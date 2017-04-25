//
//  UserState.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-04-24.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import Foundation

class UserState: NSObject {
    
    static let currentUser = UserState()
    
    var uid: String?
    var username: String?
    var email: String?
}
