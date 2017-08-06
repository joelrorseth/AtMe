//
//  Constants.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-02-20.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
struct Constants {
    
    struct App {
        static let oneSignalAppId = "8bf018c1-5a99-4ab8-8652-70a4fc149019"
    }
    
    struct Assets {
        static let purpleUserImage = "user_purple"
    }
    
    struct CellIdentifiers {
        static let blockedUserCell = "BlockedUserCell"
    }
    
    struct Colors {
        static let tableViewBackground = UIColor(red: 250/255, green: 250/255, blue: 250/255, alpha: 1.0)
        static let primaryLight = UIColor(red: 180/255, green: 93/255, blue: 231/255, alpha: 1)
        static let primaryDark = UIColor(red: 115/255, green: 22/255, blue: 231/255, alpha: 1)
        static let primaryAccent = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
    }
    
    struct Errors {
        static let changeEmailError = "A problem occured while changing your email address. Please try again."
        static let changePasswordError = "A problem occured while changing your password. Please try again."
        static let createConversationError = "There was an error attempting to start the conversation. Please try again or contact support."
        static let missingFields = "Please fill in all required information."
        static let invalidCharacters = "Your fields must not contain any of the following: . $ # [ ] /"
        static let loadProfileError = "An error occured while loading this profile. Please try again once dismissed."
        static let passwordLength = "Your password must be 6 or more characters."
        static let usernameLength = "Your username must be 4 or more valid characters."
        static let usernameTaken = "Your @Me username must be unique, please choose another."
        static let signInBadConfig = "Sign In configuration was unsuccessful. Please try again."
        static let displayPictureMissing = "An error occured while setting your new picture. Please try again."
        static let unestablishedCurrentUser = "An error occured while authorizing. Please try signing in again."
        static let conversationAlreadyExists = "You already have an open conversation with this user."
    }
    
    struct Fonts {
        static let emptyViewMessageFont = UIFont(name: "Avenir Next", size: 18)!
        static let lightTitle = UIFont(name: "AvenirNext-Medium", size: 20)!
        static let regularText = UIFont(name: "AvenirNext-Regular", size: 14)!
        static let boldButtonText = UIFont(name: "AvenirNext-DemiBold", size: 17)!
    }
    
    struct Limits {
        static let messageCountStandardLimit = 40
        static let messageCountIncreaseLimit = 20
        static let resultsCount = UInt(16)
    }
    
    struct Messages {
        static let cacheClearedSuccess = "Image cache was successfully emptied."
        static let confirmBlockMessage = "Are you sure you want to block this user? You will be unable to contact each other while blocked."
        static let confirmLogout = "Are you sure you want to logout?"
        static let didReportUser = "Thank you for your report. We will investigate this issue and take appropriate action within 24 hours."
        static let noBlockedUsersMessage = "You have not blocked any users."
    }
    
    struct Placeholders {
        static let messagePlaceholder = "Enter a message"
        static let pictureMessagePlaceholder = "Picture Message"
    }
    
    struct Radius {
        static let regularRadius = CGFloat(12)
    }
    
    struct Segues {
        static let createAccountSuccessSegue = "CreateAccountSuccessSegue"
        static let loadConvoSegue = "LoadConvoSegue"
        static let newConvoSegue = "NewConvoSegue"
        static let reportUserSegue = "ReportUserSegue"
        static let settingsSegue = "SettingsSegue"
        static let showAuxSegue = "ShowAuxSegue"
        static let showBlockedUsersSegue = "ShowBlockedUsersSegue"
        static let showLegalSegue = "ShowLegalSegue"
        static let showPromptSegue = "ShowPrompt"
        static let signInSuccessSegue = "SignInSuccessSegue"
        static let signUpSuccessSegue = "SignUpSuccessSegue"
        static let unwindToChatListSegue = "UnwindToChatListSegue"
        static let unwindToSignInSegue = "UnwindToSignIn"
    }
    
    struct Sizes {
        static let pictureMessageDefaultHeight = 200
        static let pictureMessageDefaultWidth = 200
    }
    
    struct Storyboard {
        static let messageId = "messageId"
    }
    
    enum UserAttribute: Int { case none = 0, firstName, lastName, email, password }
    
    struct UserAttributes {
        static let UserAttributeNames = ["None", "first name", "last name", "email address", "password"]
    }
}
