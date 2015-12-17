//
//  Cell.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/3/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import Foundation
import Spring
import DTCoreText

class Cell {
    var stream = String()
    var streamColor = String()
    var subject = String()
    var content = NSAttributedString()
    var timestamp = String()
    var name = String()
    var avatarURL = String()
    var messageID = String()
    
    //PMs
    var recipientID = String()
    var type = String()
    var recipientNames = [String]()
    var recipientEmail = [String]()
    var mention = Bool()
    
    
    init() {}
    
    init(msgStream: String, msgStreamColor: String, msgSubject: String, msgContent: String, msgTimestamp: String, msgName: String, msgAvatarURL: String, msgID: String, msgRecipientID: String, msgType: String, msgRecipients: [String], msgRecipientEmail: [String], msgMention: Bool) {
        stream = msgStream
        streamColor = msgStreamColor
        subject = msgSubject
        messageID = msgID
        content = htmlToAttributedString(msgContent + "<style>body{font-family:\"SourceSansPro-Regular\";font-size:15px;line-height:15px;}</style>")
//        let data = msgContent.dataUsingEncoding(NSUTF8StringEncoding)
//        let haha = DTHTMLAttributedStringBuilder(HTML: msgContent.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, options: nil, documentAttributes: nil)
//        let ugh = DTHTMLAttributedStringBuilder(HTML: data!, options: [DTDefaultFontSize : NSNumber(float: 12)], documentAttributes: nil)
//        content = ugh.generatedAttributedString()
        timestamp = msgTimestamp
        name = msgName
        avatarURL = msgAvatarURL
        recipientID = msgRecipientID
        type = msgType
        recipientNames = msgRecipients
        recipientEmail = msgRecipientEmail
        mention = msgMention
    }
}