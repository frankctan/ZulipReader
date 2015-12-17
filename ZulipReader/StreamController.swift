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
import DTCoreText

protocol StreamControllerDelegate: class {
    func streamController(messagesForTable: [[Cell]])
}


class StreamController : DataController {
    
    weak var delegate: StreamControllerDelegate?
    
    func getStreamMessages(narrowParams:[[String]]?) {
        var messagesURL = NSURL()
        
        if narrowParams == nil {
            messagesURL = getURL(.GetStreamMessages(anchor: userData.pointer, before: 50, after: 0))
        } else {
            messagesURL = getURL(.GetNarrowMessages(anchor: userData.pointer, before: 50, after: 0, narrowParams: narrowParams!))
        }
        Alamofire.request(.GET, messagesURL, headers: userData.header).responseJSON {[weak self] res in
            let responseJSON = JSON(data: res.data!)
            guard responseJSON["result"].stringValue == "success" else {return}
            let response = responseJSON["messages"].arrayValue
            guard let controller = self else {return}
            controller.getSubscriptions(){
                streamColorLookup = $0
                let messagesForTable = controller.parseMessages(response, colorLookupTable: streamColorLookup)
                controller.delegate?.streamController(messagesForTable)
            }
        }
    }
    
    func postMessage(type:String, content:String, to: [String], subject:String?) {
        let postMessageURL = getURL(.PostMessage(type: type, content: content, to: to, subject: subject))
        Alamofire.request(.POST, postMessageURL, headers: userData.header).responseJSON {res in
            let responseJSON = JSON(data: res.data!)
            guard responseJSON["result"].stringValue == "success" else {
                print("error sending message")
                return
            }
        }
    }
//    
//    func callLongPoll() {
//        longPoll() {result in
//            
//            
//        }
//    }
//    
//    func longPoll(completionHandler: (result: [JSON]) -> Void) {
//        let longPollURL = getURL(.longPoll(queueID: userData.queueID, lastEventId: "-1"))
//        Alamofire.request(.GET, longPollURL, headers: userData.header).responseJSON {res in
//            let responseJSON = JSON(data:res.data!)
//            guard responseJSON["result"].stringValue == "success" else {
//                print("long poll error")
//                return
//            }
//            completionHandler(result: responseJSON["events"].arrayValue)
//        }
//    }
    
    func getSubscriptions(completionHandler:[String:String]->Void) {
        let subscriptionURL = getURL(.GetSubscriptions)
        Alamofire.request(.GET, subscriptionURL, headers: userData.header).responseJSON {[weak self] res in
            var colorDict = [String:String]()
            let responseJSON = JSON(data: res.data!)
            guard responseJSON["result"].stringValue == "success" else {return}
            let response = responseJSON["subscriptions"].arrayValue
            guard let controller = self else {return}
            colorDict = controller.parseColors(response)
            completionHandler(colorDict)
        }
    }
    
    func parseColors(allSubs: [JSON]) -> [String:String] {
        var colorDict = [String:String]()
        for subs in allSubs {
            colorDict[subs["name"].stringValue] = subs["color"].stringValue
        }
        streamColorLookup = colorDict
        return colorDict
    }
    
    func parseMessages(allMessages: [JSON], colorLookupTable: [String:String]) -> [[Cell]] {
        
        var messagesForTable = [[Cell]]()
        struct Previous {
            var stream = ""
            var subject = ""
            var recipientEmail:Set<String> = []
        }
        
        var stored = Previous()
        var sectionCounter = 0
        var firstTime = true
        
        for message in allMessages {
            let name = message["sender_full_name"].stringValue
            var content = message["content"].stringValue
            let avatarURL = message["avatar_url"].stringValue
            let stream = message["display_recipient"].stringValue
            var streamColor:String {
                if message["type"].stringValue == "private" {
                    return "6F7179"
                } else {
                    if streamColorLookup[stream] != nil {
                        return streamColorLookup[stream]!
                    } else {
                        return "282B35"
                    }
                }
            }
            let subject = message["subject"].stringValue
            let messageID = message["id"].stringValue
            let messageRecipient = message["recipient_id"].stringValue
            let type = message["type"].stringValue
            let recipientNames = message["display_recipient"].arrayValue.map({$0["full_name"].stringValue})
            let recipientEmail = message["display_recipient"].arrayValue.map({$0["email"].stringValue})
            var mention: Bool {
                let flags = message["flags"].arrayValue
                for flag in flags {
                    if flag.stringValue == "mentioned" { return true }
                }
                return false
            }
            
            if firstTime {
                stored.stream = stream
                stored.subject = subject
                stored.recipientEmail = Set(recipientEmail)
                messagesForTable.append([Cell]())
                firstTime = false
            }
            
            //Swift adds an extra "\n" to paragraph tags so we replace with span.
            content = content.stringByReplacingOccurrencesOfString("<p>", withString: "<span>")
            content = content.stringByReplacingOccurrencesOfString("</p>", withString: "</span>")
            
            let timestamp = NSDate(timeIntervalSince1970: (message["timestamp"].doubleValue))
            let formattedTimestamp = timeAgoSinceDate(timestamp, numericDates: true)
            
            let setRecipientEmail = Set(recipientEmail)
            
            if stored.stream != stream || stored.subject != subject || setRecipientEmail != stored.recipientEmail {
                messagesForTable.append([Cell]())
                sectionCounter += 1
            }
//            print("stored: \("
            
            messagesForTable[sectionCounter].append(Cell(
                msgStream: stream,
                msgStreamColor: streamColor,
                msgSubject: subject,
                msgContent: content,
                msgTimestamp: formattedTimestamp,
                msgName: name,
                msgAvatarURL: avatarURL,
                msgID: messageID,
                msgRecipientID: messageRecipient,
                msgType: type,
                msgRecipients: recipientNames,
                msgRecipientEmail: recipientEmail,
                msgMention: mention))
            
            stored.stream = stream
            stored.subject = subject
            stored.recipientEmail = setRecipientEmail
        }
        
        return messagesForTable
    }
}
