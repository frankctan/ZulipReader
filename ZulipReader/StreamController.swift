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
import Locksmith
import RealmSwift

protocol StreamControllerDelegate: class {
  func statusUpdate(flag: Bool)
  func didFetchMesssages(messages: [[TableCell]])
}

class StreamController : DataController {
  
  weak var delegate: StreamControllerDelegate?
  
  let realm = try! Realm()
  
  var subscription: [String:String] = [:]
  
  var registration = Registration()
  
  struct Registration {
    var pointer = Int()
    var maxMessageID = Int()
    var queueID = String()
    var eventID = Int()
    var subscription = [JSON]()
    
    let numBefore = 50
    let numAfter = 50
    
    init() {}
    
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
//    realm.deleteAll()
    do {
      try Locksmith.deleteDataForUserAccount("default")
    }
    catch {fatalError("unable to clear Locksmith")}
  }
  
  //MARK: Register
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
  
  //writes subscription dictionary, realm persistence, other registration info
  func recordRegistration(registration: Registration) -> Future<Registration, ZulipErrorDomain> {
    for sub in registration.subscription {
      subscription[sub["name"].stringValue] = sub["color"].stringValue
    }
    subscriptionsToRealm(registration.subscription)
    self.registration = registration
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
      .andThen(recordRegistration)
  }
  
  //MARK: Get Stream Messages
  func createMessageRequest(params: Registration) -> Future<URLRequestConvertible, ZulipErrorDomain> {
    let urlRequest = Router.GetOldMessages(anchor: params.maxMessageID, before: params.numBefore, after: params.numAfter)
    return Future<URLRequestConvertible, ZulipErrorDomain>(value: urlRequest)
  }
  
  func createMessageRequest(params: Registration, narrow: String?) -> Future<URLRequestConvertible, ZulipErrorDomain> {
    let urlRequest: URLRequestConvertible
    if let narrowRequest = narrow {
      urlRequest = Router.GetNarrowMessages(anchor: params.maxMessageID, before: params.numBefore, after: params.numAfter, narrow: narrowRequest)
    }
    else {
      urlRequest = Router.GetOldMessages(anchor: params.maxMessageID, before: params.numBefore, after: params.numAfter)
    }
    return Future<URLRequestConvertible, ZulipErrorDomain>(value: urlRequest)
  }
  
  typealias responseJSON = [JSON]
  
  func parseStreamMessages(params: Registration) -> Future<[Message], ZulipErrorDomain> {
    return createMessageRequest(params)
      .andThen(AlamofireRequest)
      .andThen(parseMessageRequest)
      .andThen(createMessageObject)
  }
  
  func loadStreamMessages() {
    register()
      .andThen(parseStreamMessages)
      .start {result in
        switch result {
        case .Success(let boxedMessages):
          let messages = boxedMessages.unbox
          self.messagesToRealm(messages)
          let tableMessages = self.tableViewMessages(messages)
          self.delegate?.didFetchMesssages(tableMessages)
        case .Error(let error):
          print(error.unbox.description)
        }
    }
  }
  
  func parseNarrowMessages(params: Registration, narrow: String) -> Future<[Message], ZulipErrorDomain> {
    return createMessageRequest(params, narrow: narrow)
      .andThen(AlamofireRequest)
      .andThen(parseMessageRequest)
      .andThen(createMessageObject)
  }
  
  func loadNarrowMessages(narrow: String) {
    parseNarrowMessages(self.registration, narrow: narrow)
      .start {result in
        switch result {
        case .Success(let boxedMessages):
          let messages = boxedMessages.unbox
          let tableMessages = self.tableViewMessages(messages)
          self.delegate?.didFetchMesssages(tableMessages)
        case .Error(let error):
          print(error.unbox.description)
        }
    }
  }
  
  func parseMessageRequest(response: JSON) -> Future<responseJSON, ZulipErrorDomain> {
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
  
  func createMessageObject(messages: [JSON]) -> Future<[Message], ZulipErrorDomain> {
    return Future<[Message], ZulipErrorDomain>(operation: {completion in
      let result: Result<[Message], ZulipErrorDomain>
      var results = [Message]()
      guard let ownEmail = NSUserDefaults.standardUserDefaults().stringForKey("email") else {fatalError()}
      
      for message in messages {
        var messageDict = message.dictionaryObject!

        //assigns most of Message
        let msg = Message(value: messageDict)
        
        //flag and display_recipient are [String]
        //need special treatment
        if let flags = messageDict["flags"] {
          msg.flags = flags as! [String]
        }
        
        //assigns streamColor
        if msg.type == "private", let privateRecipients = message["display_recipient"].array {
          msg.display_recipient = privateRecipients.map {$0["email"].stringValue}
          
          msg.privateFullName =
            privateRecipients
              .filter {if $0["email"].stringValue == ownEmail {return false}; return true}
              .map {$0["full_name"].stringValue}
          
          msg.streamColor = "none"
        }
        
        if msg.type == "stream",let streamRecipient = message["display_recipient"].string {
          msg.display_recipient = [streamRecipient]
          msg.streamColor = self.subscription[streamRecipient]!
        }
        results.append(msg)
      }
      result = Result.Success(Box(results))
      completion(result)
    })
  }
  
  func messagesToRealm(messages: [Message]) {
    print("writing messages")
    print("save path: \(realm.path)")
    for message in messages {
      do {
        try realm.write {
          realm.add(message)
        }
      } catch { fatalError("msgs: could not write to realm") }
    }
  }
  
  //MARK: Prepare messages for table view
  func tableViewMessages(messages: [Message]) -> [[TableCell]] {
    //    let messages = realm.objects(Message).sorted("timestamp", ascending: true)
    var previous = TableCell()
    var result = [[TableCell]()]
    var sectionCounter = 0
    for message in messages {
      var cell = TableCell(message)
      
      cell.attributedContent = processMarkdown(message.content)
      
      if previous.isEmpty {
        result[sectionCounter].append(cell)
        previous = cell
        continue
      }
      
      if previous.display_recipient != cell.display_recipient ||
        previous.subject != cell.subject ||
        previous.type != cell.type {
          sectionCounter++
          result.append([cell])
      }
      else {
        if previous.sender_full_name == cell.sender_full_name {
          cell.cellType = CellTypes.ExtendedCell
        }
        result[sectionCounter].append(cell)
      }
      previous = cell
    }
    print(result.count)
    return result
  }
  
  func processMarkdown(text: String) -> NSAttributedString! {
    //Swift adds an extra "\n" to paragraph tags so we replace with span.
    var text = text.stringByReplacingOccurrencesOfString("<p>", withString: "<span>")
    text = text.stringByReplacingOccurrencesOfString("</p>", withString: "</span>")
    //Stolen from the original zulip-ios project
    let style = ["<style>",
      "body{font-family:\"SourceSansPro-Regular\";font-size:15px;line-height:15px;}",
      "span.user-mention {padding: 2px 4px; background-color: #F2F2F2; border: 1px solid #e1e1e8;}",
      ".hll{background-color:#ffc}{background:#f8f8f8} .c{color:#408080;font-style:italic} .err{border:1px solid #f00} .k{color:#008000;font-weight:bold} .o{color:#666} .cm{color:#408080;font-style:italic} .cp{color:#bc7a00} .c1{color:#408080;font-style:italic} .cs{color:#408080;font-style:italic} .gd{color:#a00000} .ge{font-style:italic} .gr{color:#f00} .gh{color:#000080;font-weight:bold} .gi{color:#00a000} .go{color:#808080} .gp{color:#000080;font-weight:bold} .gs{font-weight:bold} .gu{color:#800080;font-weight:bold} .gt{color:#0040d0} .kc{color:#008000;font-weight:bold} .kd{color:#008000;font-weight:bold} .kn{color:#008000;font-weight:bold} span.kp{color:#008000} .kr{color:#008000;font-weight:bold} .kt{color:#b00040} .m{color:#666} .s{color:#ba2121} .na{color:#7d9029} .nb{color:#008000} .nc{color:#00f;font-weight:bold} .no{color:#800} .nd{color:#a2f} .ni{color:#999;font-weight:bold} .ne{color:#d2413a;font-weight:bold} .nf{color:#00f} .nl{color:#a0a000} .nn{color:#00f;font-weight:bold} .nt{color:#008000;font-weight:bold} .nv{color:#19177c} .ow{color:#a2f;font-weight:bold} .w{color:#bbb} .mf{color:#666} .mh{color:#666} .mi{color:#666} .mo{color:#666} .sb{color:#ba2121} .sc{color:#ba2121} .sd{color:#ba2121;font-style:italic} .s2{color:#ba2121} .se{color:#b62;font-weight:bold} .sh{color:#ba2121} .si{color:#b68;font-weight:bold} .sx{color:#008000} .sr{color:#b68} .s1{color:#ba2121} .ss{color:#19177c} .bp{color:#008000} .vc{color:#19177c} .vg{color:#19177c} .vi{color:#19177c} .il{color:#666}",
      "blockquote {border-left-color: #dddddd;border-left-style: solid;border-left: 5px;}",
      "a {color:0088cc}",
      "code {padding: 2px 4px;color: #d14;background-color: #F5F5F5;border: 1px solid #e1e1e8;}",
      "img {max-height: 200px}",
      "</style>"].reduce("",combine: +)
    text += style
    let htmlData = text.dataUsingEncoding(NSUTF16StringEncoding, allowLossyConversion: false)
    let htmlString: NSAttributedString?
    do {
      htmlString = try NSAttributedString(data: htmlData!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
    } catch _ {
      htmlString = nil
    }
    return htmlString
  }
}


