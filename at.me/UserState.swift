//
//  UserState.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-04-24.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import Foundation
import UIKit.UIImage

class UserState: NSObject {
    
    static let currentUser = UserState()
    
    var displayName: String?
    var displayPicture: UIImage?
    var email: String?
    var notificationID: String?
    var uid: String?
    var username: String?
}
