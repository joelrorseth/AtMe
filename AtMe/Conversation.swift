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
    
    // Assume that every convo will only have two members (current user and another)
    // In ChatListViewController, we don't add current user to these lists
    // Thus only the 'other user' will appear, exclusively in either inactive or active
    
    var activeMemberUIDs = Set<String>()
    var inactiveMemberUIDs = Set<String>()
    
    
    /** Initializer */
    init(convoID: String, name: String, newestMessage: String, timestamp: Date, newestMessageTimestamp: String, unseenMessages: Bool) {
        self.convoID = convoID
        self.name = name
        self.newestMessage = newestMessage
        self.timestamp = timestamp
        self.newestMessageTimestamp = newestMessageTimestamp
        self.unseenMessages = unseenMessages
    }
}
