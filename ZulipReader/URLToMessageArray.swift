//
//  URLToMessageArray.swift
//  ZulipReader
//
//  Created by Frank Tan on 3/21/16.
//  Copyright © 2016 Frank Tan. All rights reserved.
//

import Foundation
import Alamofire
import RealmSwift
import SwiftyJSON

protocol URLToMessageArrayDelegate: class {
  func urlToMessageArrayDidFinish(action: Action, messages: [Message])
}

class URLToMessageArray: NetworkOperation {
  
  let action: Action
  let subscription: [String: String]
  var messages = [Message]()
  
  weak var delegate: URLToMessageArrayDelegate?
  
  init(action: Action, subscription: [String: String]) {
    self.action = action
    self.subscription = subscription
  }
  
  override func main() {
    self.messagePipeline(self.action).start {result in
      if self.cancelled {
        return
      }
      
      switch result {
      case .Success(let box):
        self.messages = box.unbox
        if !self.messages.isEmpty {
          self.messagesToRealm(self.messages)
          self.saveMinMaxId(self.messages)
          self.delegate?.urlToMessageArrayDidFinish(self.action, messages: self.messages)
        }
        self.complete()
        
      case .Error(let box):
        let error = box.unbox
        print("error: \(error)")
        self.complete()
      }
    }
  }
  
  func getNewMessages() -> [Message] {
    return self.messages
  }
  
  private func messagePipeline(action: Action) -> Future<[Message], ZulipErrorDomain> {
    return createRequestParameters(action)
      .andThen(createMessageRequest)
      .andThen(AlamofireRequest)
      .andThen(processResponse)
  }
  
  private func createMessageRequest(params: MessageRequestParameters) -> Future<URLRequestConvertible, ZulipErrorDomain> {
    let urlRequest: URLRequestConvertible = Router.GetMessages(anchor: params.numAnchor, before: params.numBefore, after: params.numAfter, narrow: params.narrow)
    return Future<URLRequestConvertible, ZulipErrorDomain>(value: urlRequest)
  }
  
  private func createRequestParameters(action: Action) -> Future<MessageRequestParameters, ZulipErrorDomain> {
    var params = MessageRequestParameters()
    let (minAnchor, maxAnchor) = getAnchor()
    
    switch action.userAction {
    case .Focus:
      params = MessageRequestParameters(anchor: maxAnchor, before: 20, after: 50, narrow: action.narrow.narrowString)
    case .Refresh:
      params = MessageRequestParameters(anchor: maxAnchor, before: 0, after: 50, narrow: action.narrow.narrowString)
    case .ScrollUp:
      params = MessageRequestParameters(anchor: minAnchor, before: 20, after: 0, narrow: action.narrow.narrowString)
    }
    return Future<MessageRequestParameters, ZulipErrorDomain>(value: params)
  }
  
  //returns the minimum of a narrowString or the home minimum ID
  private func getAnchor() -> (Int, Int) {
    let defaults = NSUserDefaults.standardUserDefaults()
    let homeMaxId = defaults.integerForKey("homeMax")
    let homeMinId: Int
    if let minId = defaults.objectForKey("homeMin") {
      homeMinId = minId as! Int
    } else {
      homeMinId = Int.max
    }
    
    var minId = homeMinId
    if let narrowString = self.action.narrow.narrowString {
      let streamMinId = defaults.objectForKey(narrowString)
      if streamMinId != nil {
        minId = streamMinId as! Int
      }
    }
    
    return (minId, homeMaxId)
  }
  
  private func processResponse(response: JSON) -> Future<[Message], ZulipErrorDomain> {
    return parseMessageRequest(response)
      .andThen(createMessageObject)
  }
  
  private func parseMessageRequest(response: JSON) -> Future<[JSON], ZulipErrorDomain> {
    return Future<[JSON], ZulipErrorDomain>(operation: {completion in
      let result: Result<[JSON], ZulipErrorDomain>
      if let responseArray = response["messages"].array {
        result = Result.Success(Box(responseArray))
      }
      else {
        result = Result.Error(Box(ZulipErrorDomain.ZulipRequestFailure(message: "unable to retrieve responseJSON")))
      }
      completion(result)
    })
  }
  
  private func createMessageObject(messages: [JSON]) -> Future<[Message], ZulipErrorDomain> {
    return Future<[Message], ZulipErrorDomain>(operation: {completion in
      print("creating message object")
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
          msg.mentioned = msg.flags.contains("mentioned") || msg.flags.contains("wildcard_mentioned")
        }
        
        //assigns streamColor
        if msg.type == "private",
          let privateRecipients = message["display_recipient"].array {
          msg.display_recipient = privateRecipients.map {$0["email"].stringValue}
          
          msg.privateFullName = privateRecipients
            .filter {if $0["email"].stringValue == ownEmail {return false}; return true}
            .map {$0["full_name"].stringValue}
          
          var pmWithSet = Set(msg.display_recipient + [msg.sender_email])
          
          //allows PM's with yourself.
          if pmWithSet.count > 1 {
            pmWithSet.remove(ownEmail)
          }
          msg.pmWith = Array(pmWithSet)
          
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
  
  private func messagesToRealm(messages: [Message]) {
    let realm: Realm
    do {
      realm = try Realm()
    } catch let error as NSError {
      fatalError(String(error))
    }
    
    let realmMessages = realm.objects(Message).sorted("id", ascending: true).map {$0}
    let currentMessageID = realmMessages.map {$0.id}
    
    realm.beginWrite()
    for message in messages {
      if !currentMessageID.contains(message.id) {
        realm.create(Message.self, value: message)
      }
    }
    do { try realm.commitWrite()} catch {fatalError()}
    print("save path: \(realm.path)")
  }
  
  private func saveMinMaxId(messages: [Message]) {
    let defaults = NSUserDefaults.standardUserDefaults()
    let currentMinId = messages[0].id
    let currentMaxId = messages.last!.id
    
    if let narrowString = action.narrow.narrowString {
      let defaultNarrowMinId = defaults.objectForKey(narrowString)
      if defaultNarrowMinId == nil || currentMinId < (defaultNarrowMinId as! Int) {
        defaults.setInteger(currentMinId, forKey: narrowString)
      }
    }
    else {
      let defaultHomeMinId = defaults.objectForKey("homeMin")
      if defaultHomeMinId == nil || currentMinId < (defaultHomeMinId as! Int) {
        defaults.setInteger(currentMinId, forKey: "homeMin")
      }
    }
    
    let defaultMaxId = defaults.objectForKey("homeMax")
      if defaultMaxId == nil || currentMaxId > (defaultMaxId as! Int) {
      defaults.setInteger(currentMaxId, forKey: "homeMax")
    }
  }
}




