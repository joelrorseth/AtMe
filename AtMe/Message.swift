//
//  Message.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-04-28.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import Foundation

public class Message {
    
    var imageURL: String?
    var sender: String
    var text: String?
    var timestamp: Date
    
    init(imageURL: String?, sender: String, text: String?, timestamp: Date) {
        self.imageURL = imageURL
        self.sender = sender
        self.text = text
        self.timestamp = timestamp
    }
}
