//
//  Conversation.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-04-27.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import Foundation

public class Conversation {
    
    var convoId: String
    var otherUsername: String
    var newestMessage: String
    var newestMessageTimestamp: String
    
    init(convoId: String, otherUsername: String, newestMessage: String, newestMessageTimestamp: String) {
        self.convoId = convoId
        self.otherUsername = otherUsername
        self.newestMessage = newestMessage
        self.newestMessageTimestamp = newestMessageTimestamp
    }
}
