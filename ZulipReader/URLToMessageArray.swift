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
  func messageArraysDidFinish(action: Action, newMessages: [Message])
}

class URLToMessageArray: NSOperation {
  
  //override executing and finished to be KVO compliant because of networking call
  private var _executing: Bool = false
  override var executing: Bool {
    get {
      return _executing
    }
    set {
      if (_executing != newValue) {
        self.willChangeValueForKey("isExecuting")
        _executing = newValue
        self.didChangeValueForKey("isExecuting")
      }
    }
  }
  
  private var _finished: Bool = false;
  override var finished: Bool {
    get {
      return _finished
    }
    set {
      if (_finished != newValue) {
        self.willChangeValueForKey("isFinished")
        _finished = newValue
        self.didChangeValueForKey("isFinished")
      }
    }
  }
  
  weak var delegate: URLToMessageArrayDelegate?

  let action: Action
  let realm: Realm
  let realmMessages: [Message]
  let subscription: [String: String]
  let registrationMaxID: Int
  
  init(action: Action, subscription: [String: String], registrationMax: Int) {
    print("initializing URLToMessageArray")
    self.action = action
    self.subscription = subscription
    self.registrationMaxID = registrationMax
    
    do {
      realm = try Realm()
      print("realm initialized")
    } catch let error as NSError {
      fatalError(String(error))
    }
    
    realmMessages = self.realm.objects(Message).sorted("id", ascending: true).map {$0}
  }
  
  override func main() {
    print("in main")
    self.messagePipeline(self.action).start {result in
      if self.cancelled {
        return
      }
      
      switch result {
      case .Success(let box):
        let messages = box.unbox
        self.messagesToRealm(messages)
        self.delegate?.messageArraysDidFinish(self.action, newMessages: messages)
        self.complete()
        
      case .Error(let box):
        print("main - error")
        let error = box.unbox
        print("error: \(error)")
        self.complete()
      }
    }
  }
  
  private func complete() {
    self.finished = true
    self.executing = false
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
    let (minAnchor, maxAnchor) = getAnchor()
    print("getAnchor results: \(minAnchor, maxAnchor)")
    
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
  
  private func getAnchor() -> (min: Int, max: Int) {
    var realmMaxID = 0
    print("in get anchor")
    
    //TODO: for some reason, I need to redeclare realm here, but dont't need to in messagesToRealm
    let realm1: Realm
    do {
      realm1 = try Realm()
      print("realm initialized")
    } catch let error as NSError {
      fatalError(String(error))
    }

    let realmMessages1 = realm1.objects(Message).sorted("id", ascending: true).map {$0}

    let narrowedMessages: [Message] = ((realmMessages1 as NSArray).filteredArrayUsingPredicate(self.action.narrow.predicate())) as! [Message]
    print("narrowed realm")
    if let last = narrowedMessages.last {
      realmMaxID = last.id
    }
    
    //minID only used to scroll up
    var realmMinID = 0
    if let first = narrowedMessages.first {
      realmMinID = first.id
    }
    
    //offset by 1 to reduce duplicates
    return (realmMinID-1, max(realmMaxID, self.registrationMaxID)+1)
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
            pmWithSet.remove(ownEmail)
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
    print("writing messages...")
    print("save path: \(realm.path)")
    let currentMessageID = realmMessages.map {$0.id}
    realm.beginWrite()
    for message in messages {
      if !currentMessageID.contains(message.id) {
        realm.create(Message.self, value: message)
      }
    }
    do { try self.realm.commitWrite()} catch {fatalError()}
    print("finished writing")
  }
}




