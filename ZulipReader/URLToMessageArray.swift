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

class URLToMessageArray: NetworkOperation {
  
  let action: Action
  let subscription: [String: String]
  let maxId: Int
  let homeMinId: Int
  let streamMinId: [String: Int]
  
  var messages = [Message]()
  
  init(action: Action, subscription: [String: String], maxId: Int, homeMinId: Int, streamMinId: [String: Int]) {
    print("initializing URLToMessageArray")
    self.action = action
    self.subscription = subscription
    self.maxId = maxId
    self.homeMinId = homeMinId
    self.streamMinId = streamMinId
    
  }
  
  override func main() {
    self.messagePipeline(self.action).start {result in
      if self.cancelled {
        return
      }
      
      switch result {
      case .Success(let box):
        self.messages = box.unbox
        self.messagesToRealm(self.messages)
        
      case .Error(let box):
        let error = box.unbox
        print("error: \(error)")
      }
      
      self.complete()
    }
  }
  
  func getNewMessages() -> [Message] {
    return self.messages
  }
  
  private func messagePipeline(action: Action) -> Future<[Message], ZulipErrorDomain> {
    print("in message pipeline")
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
    let minAnchor = getMinAnchor()
    
    switch action.userAction {
    case .Focus:
      params = MessageRequestParameters(anchor: self.maxId, before: 20, after: 50, narrow: action.narrow.narrowString)
    case .Refresh:
      params = MessageRequestParameters(anchor: self.maxId, before: 0, after: 50, narrow: action.narrow.narrowString)
    case .ScrollUp:
      params = MessageRequestParameters(anchor: minAnchor, before: 20, after: 0, narrow: action.narrow.narrowString)
    }
    return Future<MessageRequestParameters, ZulipErrorDomain>(value: params)
  }
  
  private func getMinAnchor() -> Int {
    let minId: Int
    
    if let narrow = action.narrow.narrowString,
      let narrowMinId = self.streamMinId[narrow] {
      minId = narrowMinId
      print("narrow MinId: \(minId)")
    } else {
      minId = self.homeMinId
      print("home MinId: \(minId)")
    }
    return minId
  }
  
  private func processResponse(response: JSON) -> Future<[Message], ZulipErrorDomain> {
    print("processing JSON response")
    return parseMessageRequest(response)
      .andThen(createMessageObject)
  }
  
  private func parseMessageRequest(response: JSON) -> Future<[JSON], ZulipErrorDomain> {
    return Future<[JSON], ZulipErrorDomain>(operation: {completion in
      print("parsing message request")
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

    print("writing messages...")
    print("save path: \(realm.path)")
    let currentMessageID = realmMessages.map {$0.id}
    realm.beginWrite()
    for message in messages {
      if !currentMessageID.contains(message.id) {
        realm.create(Message.self, value: message)
      }
    }
    do { try realm.commitWrite()} catch {fatalError()}
    print("finished writing")
  }
}




