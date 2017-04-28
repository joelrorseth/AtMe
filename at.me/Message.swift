//
//  Message.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-04-28.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import Foundation

public class Message {
    
    var sender: String
    var text: String
    
    init(sender: String, text: String) {
        self.sender = sender
        self.text = text
    }
}
