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
import Locksmith
import RealmSwift

protocol StreamControllerDelegate: class {
  func statusUpdate(flag: Bool)
  //  func streamController(messagesForTable: [[Cell]])
  //  func longPollDelegate(appendMessages: [[Cell]])
}

class StreamController : DataController {
  
  weak var delegate: StreamControllerDelegate?
  let realm = try! Realm()
  
  
  struct Registration {
    var pointer = Int()
    var maxMessageID = Int()
    var queueID = String()
    var eventID = Int()
    var subscription = [JSON]()
    
    let numBefore = 50
    let numAfter = 50
    
    
    init(_ pointer: Int, _ maxMessageID: Int, _ queueID: String, _ eventID: Int, _ subscription: [JSON]) {
      self.pointer = pointer
      self.maxMessageID = maxMessageID
      self.queueID = queueID
      self.eventID = eventID
      self.subscription = subscription
    }
  }
  
  func isLoggedIn() -> Bool {
    if let basicAuth = Locksmith.loadDataForUserAccount("default"),
      let authHead = basicAuth["Authorization"] as? String {
        Router.basicAuth = authHead
        return true
    }
    return false
  }
  
  func clearDefaults() {
    Router.basicAuth = nil
    realm.deleteAll()
    do {
      try Locksmith.deleteDataForUserAccount("default")
    }
    catch {fatalError("unable to clear Locksmith")}
  }
  
  func createRegistrationRequest() -> Future<URLRequestConvertible, ZulipErrorDomain> {
    let urlRequest = Router.Register
    return Future<URLRequestConvertible, ZulipErrorDomain>(value: urlRequest)
  }
  
  func getStreamAndAchor(response: JSON) -> Future<Registration, ZulipErrorDomain> {
    return Future<Registration, ZulipErrorDomain>(operation: { completion in
      let result: Result<Registration, ZulipErrorDomain>
      
      if let pointer = response["pointer"].int,
        let maxID = response["max_message_id"].int,
        let queueID = response["queue_id"].string,
        let eventID = response["last_event_id"].int,
        let subs = response["subscriptions"].array {
          
          let registration = Registration(pointer, maxID, queueID, eventID, subs)
          result = Result.Success(Box(registration))
      }
      else {
        result = Result.Error(Box(ZulipErrorDomain.ZulipRequestFailure(message: "unable to assign registration")))
      }
      completion(result)
    })
  }
  
  func writeSubscriptionsToRealm(registration: Registration) -> Future<Registration, ZulipErrorDomain> {
    subscriptionsToRealm(registration.subscription)
    return Future<Registration, ZulipErrorDomain>(value: registration)
  }
  
  func subscriptionsToRealm(subscriptions: [JSON]) {
    print("writing subscriptions")
    for subscription in subscriptions {
      let subDict = subscription.dictionaryObject
      let sub = Subscription(value: subDict!)
      do {
        try realm.write {
          realm.add(sub)
        }
      } catch { fatalError("subs: could not write to realm") }
    }
  }

  func register() -> Future<Registration, ZulipErrorDomain> {
    return createRegistrationRequest()
      .andThen(AlamofireRequest)
      .andThen(getStreamAndAchor)
      .andThen(writeSubscriptionsToRealm)
  }
  
  func createMessageRequest(params: Registration) -> Future<URLRequestConvertible, ZulipErrorDomain> {
    let urlRequest = Router.GetOldMessages(anchor: params.maxMessageID, before: params.numBefore, after: params.numAfter)
    return Future<URLRequestConvertible, ZulipErrorDomain>(value: urlRequest)
  }
  
  typealias responseJSON = [JSON]
  
  func parseResponse(response: JSON) -> Future<responseJSON, ZulipErrorDomain> {
    return Future<responseJSON, ZulipErrorDomain>(operation: {completion in
      let result: Result<responseJSON, ZulipErrorDomain>
      if let responseArray = response["messages"].array {
        result = Result.Success(Box(responseArray))
      }
      else {
        result = Result.Error(Box(ZulipErrorDomain.ZulipRequestFailure(message: "unable to retrieve responseJSON")))
      }
      completion(result)
    })
  }
  
  func parseMessages(params: Registration) -> Future<responseJSON, ZulipErrorDomain> {
    return createMessageRequest(params)
      .andThen(AlamofireRequest)
      .andThen(parseResponse)
  }
  
  func loadMessages() {
    register()
      .andThen(parseMessages)
      .start {result in
        switch result {
        case .Success(let boxedMessages):
          let messages = boxedMessages.unbox
          self.messagesToRealm(messages)
        case .Error(let error):
          print(error.unbox.description)
        }
    }
  }
  
  func messagesToRealm(messages: [JSON]) {
    print("writing messages")
    print("save path: \(realm.path)")
    for message in messages {
      let messageDict = message.dictionaryObject
      let msg = Message(value: messageDict!)
      do {
        try realm.write {
          realm.add(msg)
        }
      } catch { fatalError("msgs: could not write to realm") }
    }
  }
  

  
  //
  //  func getNarrowMessages(anchor: String, before: Int, after: Int, narrow: String) {
  //    print("getNarrowMessages")
  //    Alamofire.request(Router.GetNarrowMessages(anchor: anchor, before: before, after: after, narrow: narrow)).responseJSON {[weak self] res in
  //      let response = JSON(data:res.data!)
  //      guard let controller = self else {fatalError("unable to assign controller")}
  //      guard response["result"].stringValue == "success" else {print(response["msg"].stringValue); return}
  //      let messages = response["messages"].arrayValue
  //      controller.messagesToRealm(messages)
  //    }
  //  }
  //
  

  
  
  //
  //  func getStreamMessages(narrowParams:[[String]]?) {
  //    var messagesURL = NSURL()
  //
  //    if narrowParams == nil {
  //      messagesURL = getURL(.GetStreamMessages(anchor: userData.pointer, before: 50, after: eventID+100))
  //    } else {
  //      messagesURL = getURL(.GetNarrowMessages(anchor: userData.pointer, before: 50, after: eventID+100, narrowParams: narrowParams!))
  //
  //    }
  //    Alamofire.request(.GET, messagesURL, headers: userData.header).responseJSON {[weak self] res in
  //      let responseJSON = JSON(data: res.data!)
  //      guard responseJSON["result"].stringValue == "success" else {return}
  //      let response = responseJSON["messages"].arrayValue
  //      guard let controller = self else {return}
  //      controller.getSubscriptions(){
  //        streamColorLookup = $0
  //        let messagesForTable = controller.parseMessages(response, colorLookupTable: streamColorLookup)
  //        controller.delegate?.streamController(messagesForTable)
  //      }
  //    }
  //  }
  //
  //  func postMessage(type:String, content:String, to: [String], subject:String?) {
  //    let postMessageURL = getURL(.PostMessage(type: type, content: content, to: to, subject: subject))
  //    print(postMessageURL)
  //    Alamofire.request(.POST, postMessageURL, headers: userData.header).responseJSON {res in
  //      let responseJSON = JSON(data: res.data!)
  //      guard responseJSON["result"].stringValue == "success" else {
  //        print("error sending message")
  //        return
  //      }
  //    }
  //  }
  //
  //  func callLongPoll() {
  //    var appendMessages = [[Cell]]()
  //    longPoll() {result in
  //      self.eventID += 1
  //      guard !result.isEmpty else {return}
  //      if result[0]["type"].stringValue == "heartbeart" {
  //        print("heartbeat")
  //        return
  //      }
  //      print(result[0]["message"])
  //      appendMessages = self.parseMessages([result[0]["message"]], colorLookupTable: streamColorLookup)
  //      self.delegate?.longPollDelegate(appendMessages)
  //    }
  //  }
  //
  //  func longPoll(completionHandler: (result: [JSON]) -> Void) {
  //    let longPollURL = getURL(.longPoll(queueID: userData.queueID, lastEventId: String(eventID)))
  //    Alamofire.request(.GET, longPollURL, headers: userData.header).responseJSON {res in
  //      let responseJSON = JSON(data:res.data!)
  //      guard responseJSON["result"].stringValue == "success" else {
  //        print("long poll error")
  //        return
  //      }
  //      let response = responseJSON["events"].arrayValue
  //      completionHandler(result: response)
  //    }
  //  }
  //
  //  func parseColors(allSubs: [JSON]) -> [String:String] {
  //    var colorDict = [String:String]()
  //    for subs in allSubs {
  //      colorDict[subs["name"].stringValue] = subs["color"].stringValue
  //    }
  //    streamColorLookup = colorDict
  //    return colorDict
  //  }
  //
  //  func parseMessages(allMessages: [JSON], colorLookupTable: [String:String]) -> [[Cell]] {
  //
  //    var messagesForTable = [[Cell]]()
  //    struct Previous {
  //      var stream = ""
  //      var subject = ""
  //      var recipientEmail:Set<String> = []
  //    }
  //
  //    var stored = Previous()
  //    var sectionCounter = 0
  //    var firstTime = true
  //
  //    for message in allMessages {
  //      let name = message["sender_full_name"].stringValue
  //      var content = message["content"].stringValue
  //      let avatarURL = message["avatar_url"].stringValue
  //      let stream = message["display_recipient"].stringValue
  //      var streamColor:String {
  //        if message["type"].stringValue == "private" {
  //          return "6F7179"
  //        } else {
  //          if streamColorLookup[stream] != nil {
  //            return streamColorLookup[stream]!
  //          } else {
  //            return "282B35"
  //          }
  //        }
  //      }
  //      let subject = message["subject"].stringValue
  //      let messageID = message["id"].stringValue
  //      let messageRecipient = message["recipient_id"].stringValue
  //      let type = message["type"].stringValue
  //      let recipientNames = message["display_recipient"].arrayValue.map({$0["full_name"].stringValue})
  //      let recipientEmail = message["display_recipient"].arrayValue.map({$0["email"].stringValue})
  //      var mention: Bool {
  //        let flags = message["flags"].arrayValue
  //        for flag in flags {
  //          if flag.stringValue == "mentioned" { return true }
  //        }
  //        return false
  //      }
  //
  //      var setRecipientEmail = Set(recipientEmail)
  //      if setRecipientEmail.count > 1 {
  //        setRecipientEmail.remove(userData.email)
  //      }
  //
  //      if firstTime {
  //        stored.stream = stream
  //        stored.subject = subject
  //        stored.recipientEmail = setRecipientEmail
  //        messagesForTable.append([Cell]())
  //        firstTime = false
  //      }
  //
  //      //Swift adds an extra "\n" to paragraph tags so we replace with span.
  //      content = content.stringByReplacingOccurrencesOfString("<p>", withString: "<span>")
  //      content = content.stringByReplacingOccurrencesOfString("</p>", withString: "</span>")
  //
  //      let timestamp = NSDate(timeIntervalSince1970: (message["timestamp"].doubleValue))
  //      let formattedTimestamp = timeAgoSinceDate(timestamp, numericDates: true)
  //
  //      if stored.stream != stream || stored.subject != subject || setRecipientEmail != stored.recipientEmail {
  //        messagesForTable.append([Cell]())
  //        sectionCounter += 1
  //      }
  //
  //      messagesForTable[sectionCounter].append(Cell(
  //        msgStream: stream,
  //        msgStreamColor: streamColor,
  //        msgSubject: subject,
  //        msgContent: content,
  //        msgTimestamp: formattedTimestamp,
  //        msgName: name,
  //        msgAvatarURL: avatarURL,
  //        msgID: messageID,
  //        msgRecipientID: messageRecipient,
  //        msgType: type,
  //        msgRecipients: recipientNames,
  //        msgRecipientEmail: setRecipientEmail,
  //        msgMention: mention))
  //
  //      stored.stream = stream
  //      stored.subject = subject
  //      stored.recipientEmail = setRecipientEmail
  //    }
  //
  //    return messagesForTable
  //  }
}
