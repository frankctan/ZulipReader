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
    func streamController(messagesForTable: [[Cell]])
}


class StreamController : DataController {
    
    weak var delegate: StreamControllerDelegate?
    
    func getMessages() {
        let messagesURL = getURL(.GetMessages(anchor: userData.pointer, before: 12, after: 0))
        Alamofire.request(.GET, messagesURL, headers: userData.header).responseJSON {[weak self] res in
            let responseJSON = JSON(data: res.data!)
            guard responseJSON["result"].stringValue == "success" else {return}
            let response = responseJSON["messages"].arrayValue
            print("self: \(self)")
            guard let controller = self else {return}
            print("controller: \(controller)")
            var colorDict = [String:String]()
            controller.getSubscriptions(){
                colorDict = $0
                let messagesForTable = controller.parseMessages(response, colorLookupTable: colorDict)
                controller.delegate?.streamController(messagesForTable)
            }
        }
    }
    
    func getSubscriptions(completionHandler:[String:String]->Void) {
        let subscriptionURL = getURL(.GetSubscriptions)
        print(subscriptionURL)
        Alamofire.request(.GET, subscriptionURL, headers: userData.header).responseJSON {[weak self] res in
            var colorDict = [String:String]()
            let responseJSON = JSON(data: res.data!)
//            print("responseJSON: \(responseJSON)")
            guard responseJSON["result"].stringValue == "success" else {return}
            let response = responseJSON["subscriptions"].arrayValue
//            print("response: \(response)")
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
        return colorDict
    }
    
    func parseMessages(allMessages: [JSON], colorLookupTable: [String:String]) -> [[Cell]] {
        
        var messagesForTable = [[Cell]]()
        struct Previous {
            var stream = ""
            var subject = ""
        }
        
        var stored = Previous()
        var sectionCounter = 0
        var firstTime = true
        
        for message in allMessages {
            let name = message["sender_full_name"].stringValue
            var content = message["content"].stringValue
            let avatarURL = message["avatar_url"].stringValue
            let stream = message["display_recipient"].stringValue
            let streamColor = colorLookupTable[stream]!
            let subject = message["subject"].stringValue
            
            if firstTime {
                stored.stream = stream
                stored.subject = subject
                messagesForTable.append([Cell]())
                firstTime = false
            }
            
            //Swift adds an extra "\n" to paragraph tags so we replace with span.
            content = content.stringByReplacingOccurrencesOfString("<p>", withString: "<span>")
            content = content.stringByReplacingOccurrencesOfString("</p>", withString: "</span>")
            
            let timestamp = NSDate(timeIntervalSince1970: (message["timestamp"].doubleValue))
            let formattedTimestamp = timeAgoSinceDate(timestamp, numericDates: true)
            
            if stored.stream == stream && stored.subject == subject {
                messagesForTable[sectionCounter].append(Cell(
                    msgStream: stream,
                    msgStreamColor: streamColor,
                    msgSubject: subject,
                    msgContent: content,
                    msgTimestamp: formattedTimestamp,
                    msgName: name,
                    msgAvatarURL: avatarURL))
            } else {
                sectionCounter += 1
                messagesForTable.append([Cell]())
                messagesForTable[sectionCounter].append(Cell(
                    msgStream: stream,
                    msgStreamColor: streamColor,
                    msgSubject: subject,
                    msgContent: content,
                    msgTimestamp: formattedTimestamp,
                    msgName: name,
                    msgAvatarURL: avatarURL))
            }
            
            stored.stream = stream
            stored.subject = subject
        }
        
        return messagesForTable
    }
}
