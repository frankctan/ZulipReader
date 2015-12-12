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
    var messageID = String()
    
    init() {
    }
    
    init(msgStream: String, msgStreamColor: String, msgSubject: String, msgContent: String, msgTimestamp: String, msgName: String, msgAvatarURL: String, msgID: String) {
        stream = msgStream
        streamColor = msgStreamColor
        subject = msgSubject
        messageID = msgID
        content = msgContent
        timestamp = msgTimestamp
        name = msgName
        avatarURL = msgAvatarURL
    }
}