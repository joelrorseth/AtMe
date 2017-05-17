//
//  Constants.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-02-20.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
struct Constants {
    
    struct Text {
        static let defaultTextSize = 14
    }
    
    struct Segues {
        static let signInSuccessSegue = "SignInSuccessSegue"
        static let signUpSuccessSegue = "SignUpSuccessSegue"
        static let loadConvoSegue = "LoadConvoSegue"
    }
    
    struct Storyboard {
        static let messageId = "messageId"
    }
    
    struct Colors {
        static let primaryColor = UIColor.init(red: 185, green: 24, blue: 19, alpha: 1)
    }
    
    enum UserAttribute: Int { case none = 0, displayName, firstName, lastName}
    
    struct UserAttributes {
        static let UserAttributeNames = ["None", "display name", "first name", "last name"]
    }
}
