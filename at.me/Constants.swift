//
//  Constants.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-02-20.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
struct Constants {
    
    struct Errors {
        static let missingFields = "Please fill in all required information"
        static let invalidCharacters = "Your fields must not contain any of the following: . $ # [ ] /"
        static let passwordLength = "Your password must be 6 or more characters."
        static let usernameLength = "Your username must be 4 or more valid characters."
        static let usernameTaken = "Your @Me username must be unique, please choose another."
        static let signInBadConfig = "Sign In configuration was unsuccessful. Please try again."
        static let DisplayPictureMissing = "An error occured while setting your new picture. Please try again."
    }
    
    struct Fonts {
        static let lightTitle = UIFont(name: "AvenirNext-Medium", size: 20)!
        static let regularText = UIFont(name: "AvenirNext-Regular", size: 14)!
    }
    
    struct Text {
        static let defaultTextSize = 14
    }
    
    struct Radius {
        static let regularRadius = CGFloat(12)
    }
    
    struct Segues {
        static let signInSuccessSegue = "SignInSuccessSegue"
        static let signUpSuccessSegue = "SignUpSuccessSegue"
        static let loadConvoSegue = "LoadConvoSegue"
        static let createAccountSuccessSegue = "CreateAccountSuccessSegue"
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

        
        static let primaryLight = UIColor(red: 180/255, green: 93/255, blue: 231/255, alpha: 1)
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
