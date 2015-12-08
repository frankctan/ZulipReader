//
//  StreamController.swift
//  ZulipReader
//
//  Created by Frank Tan on 11/28/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import Spring

protocol StreamControllerDelegate: class {
    func streamController(cellMessages: [Cell])
}


class StreamController : DataController {
    
    weak var delegate: StreamControllerDelegate?
    
    func getMessages() {
        let messagesURL = getURL(.GetMessages(anchor: userData.pointer, before: 12, after: 0))
        Alamofire.request(.GET, messagesURL, headers: userData.header).responseJSON {[weak self] res in
            let responseJSON = JSON(data: res.data!)
            guard responseJSON["result"].stringValue == "success" else {return}
            let response = responseJSON["messages"].arrayValue
            guard let controller = self else {return}
            let cellMessages = controller.parseMessages(response)
            controller.delegate?.streamController(cellMessages)
        }
    }
    
    func parseMessages(allMessages: [JSON]) -> [Cell] {
        
        var messagesWithHeaders = [Cell]()
        
        struct Previous {
            var stream = ""
            var subject = ""
            var name = ""
        }
        
        var stored = Previous()
        
        for message in allMessages {
            let name = message["sender_full_name"].stringValue
            var content = message["content"].stringValue
            let avatarURL = message["avatar_url"].stringValue
            let stream = message["display_recipient"].stringValue
            let subject = message["subject"].stringValue
            
            content = content.stringByReplacingOccurrencesOfString("<p>", withString: "<span>")
            content = content.stringByReplacingOccurrencesOfString("</p>", withString: "</span>")
            
            let timestamp = NSDate(timeIntervalSince1970: (message["timestamp"].doubleValue))
            let formattedTimestamp = timeAgoSinceDate(timestamp, numericDates: true)
            
            
            if stored.stream == stream && stored.subject == subject {
                if stored.name != name {
                    messagesWithHeaders.append(UserHeaderCell(msgName: name, msgAvatarURL: avatarURL))
                }
                messagesWithHeaders.append(MessageCell(msgContent: content, msgTimestamp: formattedTimestamp))
            } else {
                messagesWithHeaders.append(StreamHeaderCell(msgStream: stream, msgSubject: subject))
                messagesWithHeaders.append(UserHeaderCell(msgName: name, msgAvatarURL: avatarURL))
                messagesWithHeaders.append(MessageCell(msgContent: content, msgTimestamp: formattedTimestamp))
            }
            
            stored.stream = stream
            stored.subject = subject
            stored.name = name
        }
        
        return messagesWithHeaders
    }
}

//{
//    "msg": "",
//    "messages": [
//    {
//    "recipient_id": 20330,
//    "sender_email": "bac1087@gmail.com",
//    "timestamp": 1448931264,
//    "display_recipient": "455 Broadway",
//    "sender_id": 8854,
//    "sender_full_name": "Benjamin Adam Cohen (W1'15)",
//    "sender_domain": "students.hackerschool.com",
//    "content": "<p>Whatever is decided about 'making presentations better', it would be useful if it could be boiled down to a kind of 5 point list for easy reference. Kind of like the social rules, it will help if its concise</p>",
//    "gravatar_hash": "c44cfbb3d7938bd98a97ab3119bfe35b",
//    "avatar_url": "https://secure.gravatar.com/avatar/c44cfbb3d7938bd98a97ab3119bfe35b?d=identicon",
//    "flags": [
//    "read"
//    ],
//    "client": "desktop app Mac 0.5.1",
//    "content_type": "text/html",
//    "subject_links": [],
//    "sender_short_name": "bac1087",
//    "type": "stream",
//    "id": 50285316,
//    "subject": "making presentations better"
//    },