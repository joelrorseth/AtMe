//
//  Conversation.swift
//  at.me
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
    
    init(convoID: String, name: String, newestMessage: String, newestMessageTimestamp: String) {
        self.convoID = convoID
        self.name = name
        self.newestMessage = newestMessage
        self.newestMessageTimestamp = newestMessageTimestamp
    }
}
