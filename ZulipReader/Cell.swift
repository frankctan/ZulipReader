//
//  Cell.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/3/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import Foundation

class Cell {
}

class StreamHeaderCell: Cell {
    var stream = String()
    var subject = String()
    
    init(msgStream: String, msgSubject: String) {
        stream = msgStream
        subject = msgSubject
    }
}

class UserHeaderCell: Cell {
    var name = String()
    var avatarURL = String()
    
    init(msgName: String, msgAvatarURL: String) {
        name = msgName
        avatarURL = msgAvatarURL
    }
}

class MessageCell: Cell {
    var content = String()
    var timestamp = String()
    var name = String()
    var avatarURL = String()

    
    init(msgContent: String, msgTimestamp: String, msgName: String, msgAvatarURL: String) {
        content = msgContent
        timestamp = msgTimestamp
        name = msgName
        avatarURL = msgAvatarURL

    }
}