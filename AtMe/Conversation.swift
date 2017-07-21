//
//  Conversation.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-04-27.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import Foundation

public class Conversation {
    
    var convoID: String
    var name: String
    var newestMessage: String
    var newestMessageTimestamp: String
    var unseenMessages: Bool
    
    // TODO: Refactor to store date instead of string
    var timestamp: Date!
    var lastSeenByCurrentUser: Date!
    var memberUIDs = Set<String>()
    var memberNotificationIDs = Set<String>()
    
    
    /** Initializer */
    init(convoID: String, name: String, newestMessage: String, newestMessageTimestamp: String, unseenMessages: Bool) {
        self.convoID = convoID
        self.name = name
        self.newestMessage = newestMessage
        self.newestMessageTimestamp = newestMessageTimestamp
        self.unseenMessages = unseenMessages
    }
}
