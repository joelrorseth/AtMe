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
    var newestMessageTimeStamp: String
    
    init(convoId: String, otherUsername: String, newestMessage: String, newestMessageTimeStamp: String) {
        self.convoId = convoId
        self.otherUsername = otherUsername
        self.newestMessage = newestMessage
        self.newestMessageTimeStamp = newestMessageTimeStamp
    }
}
