//
//  Cell.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/3/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import Spring

class Cell {
dynamic var stream = String()
dynamic var streamColor = String()
dynamic var subject = String()
dynamic var content = NSAttributedString()
dynamic var timestamp = String()
dynamic var name = String()
dynamic var avatarURL = String()
dynamic var messageID = String()

//PMs
dynamic var recipientID = String()
dynamic var type = String()
dynamic var recipientNames = [String]()
dynamic var setRecipientEmail = Set<String>()
dynamic var mention = Bool()


  init() {}

  init(msgStream: String, msgStreamColor: String, msgSubject: String, msgContent: String, msgTimestamp: String, msgName: String, msgAvatarURL: String, msgID: String, msgRecipientID: String, msgType: String, msgRecipients: [String], msgRecipientEmail: Set<String>, msgMention: Bool) {
    stream = msgStream
    streamColor = msgStreamColor
    subject = msgSubject
    messageID = msgID
    content = htmlToAttributedString(msgContent + "<style>body{font-family:\"SourceSansPro-Regular\";font-size:15px;line-height:15px;}</style>")
    timestamp = msgTimestamp
    name = msgName
    avatarURL = msgAvatarURL
    recipientID = msgRecipientID
    type = msgType
    recipientNames = msgRecipients
    setRecipientEmail = msgRecipientEmail
    mention = msgMention
  }
}