//
//  Cell.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/3/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import Foundation

class Cell {
    var stream = String()
    var streamColor = String()
    var subject = String()

    var content = String()
    var timestamp = String()
    var name = String()
    var avatarURL = String()
    
    
    init(msgStream: String, msgStreamColor: String, msgSubject: String, msgContent: String, msgTimestamp: String, msgName: String, msgAvatarURL: String) {
        stream = msgStream
        streamColor = msgStreamColor
        subject = msgSubject
        
        content = msgContent
        timestamp = msgTimestamp
        name = msgName
        avatarURL = msgAvatarURL
    }
}