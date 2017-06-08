//
//  Constants.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-02-20.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
struct Constants {
    
    struct Fonts {
        static let regularFont = UIFont.systemFont(ofSize: CGFloat(14))
    }
    
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
    
    // MARK: In progress
    struct Colors {
        static let primaryColor = UIColor(red: 115/255, green: 22/255, blue: 231/255, alpha: 1)

        // Theme 0
//        static let primaryLight = UIColor(red: 115/255, green: 22/255, blue: 244/255, alpha: 1.0)
//        static let primaryDark = UIColor(red: 119/255, green: 61/255, blue: 115/255, alpha: 1.0)
        
        //Theme 1
//        static let primaryLight = UIColor(red: 250/255, green: 225/255, blue: 133/255, alpha: 1.0)
//        static let primaryDark = UIColor(red: 203/255, green: 152/255, blue: 175/255, alpha: 1.0)
//        static let primaryAccent = UIColor(red: 218/255, green: 177/255, blue: 161/255, alpha: 1.0)
//        static let primaryBackground = UIColor(red: 232/255, green: 219/255, blue: 212/255, alpha: 1.0)

        // Theme 2
        //static let primaryLight = UIColor(red: 131/255, green: 145/255, blue: 150/255, alpha: 1.0)
        //static let primaryDark = UIColor(red: 41/255, green: 48/255, blue: 74/255, alpha: 1.0)
        //static let primaryAccent = UIColor(red: 218/255, green: 177/255, blue: 161/255, alpha: 1.0)

        
        static let primaryLight = UIColor.white
        static let primaryDark = UIColor(red: 115/255, green: 22/255, blue: 231/255, alpha: 1)
        static let primaryAccent = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
        static let primaryText = UIColor.white
        static let primaryBackground = UIColor(red: 216/255, green: 230/255, blue: 240/255, alpha: 1.0)
    }
    
    enum UserAttribute: Int { case none = 0, displayName, firstName, lastName, email, password}
    
    struct UserAttributes {
        static let UserAttributeNames = ["None", "display name", "first name", "last name", "email address", "password"]
    }
}
