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
  func urlToMessageArrayDidFinish(messages: [Message], userAction: UserAction)
}

//we perform asynchronous operations on this thread so we want finer control over when the operation is finished
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
    //refer to Futures.swift or JaviSoto's Swift Summit Future's talk
    self.messagePipeline(self.action).start {result in
      //these are sprinkled throughout because queue.canceloperations doesn't automatically stop nsoperations
      if self.cancelled {
        self.complete()
        return
      }
      
      switch result {
      //messages need to come boxed because of a swift limitation on structs
      case .Success(let box):
        self.messages = box.unbox
        if !self.messages.isEmpty {
          //realm is our database
          self.messagesToRealm(self.messages)
          self.saveMinMaxId(self.messages)
          
          if self.cancelled {
            self.complete()
            return
          }
        }
        
      case .Error(let box):
        let error = box.unbox
        print("error: \(error)")
      }
      
      //return to StreamController
      self.delegate?.urlToMessageArrayDidFinish(self.messages, userAction: self.action.userAction)
      print("URLToMessageArray: Completed")
      self.complete()
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
    
    //after #'s are large to make sure we don't miss any messages. They also don't seem to have any noticeable performance impact.
    //in v2 - we should add checks to load more messages if new messages exceeds after.
    switch action.userAction {
    case .Focus:
      params = MessageRequestParameters(anchor: maxAnchor, before: 200, after: 20000, narrow: action.narrow.narrowString)
    case .Refresh:
      params = MessageRequestParameters(anchor: maxAnchor+1, before: 0, after: 20000, narrow: action.narrow.narrowString)
    case .ScrollUp:
      params = MessageRequestParameters(anchor: minAnchor, before: 200, after: 0, narrow: action.narrow.narrowString)
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
    //convert JSON into database Message format
    return Future<[Message], ZulipErrorDomain>(operation: {completion in
      let result: Result<[Message], ZulipErrorDomain>
      var results = [Message]()
      
      //ownEmail is helpful for PMs
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
        
        msg.content = TextMunger.processEmoji(msg.content)
        
        //assigns streamColor
        if msg.type == "private",
          let privateRecipients = message["display_recipient"].array {
          msg.display_recipient = privateRecipients.map {$0["email"].stringValue}
          
          //saves recipients that are not yourself
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
          
          //assigns stream color - if stream is not recognized, assigns default color
          if let streamColor = self.subscription[streamRecipient] {
            msg.streamColor = streamColor
          } else {
            msg.streamColor = "#000000"
          }
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
    
    var messageCounter = 0
    realm.beginWrite()
    for message in messages {
      //we don't want to save duplicates
      if !currentMessageID.contains(message.id) {
        realm.create(Message.self, value: message)
        messageCounter += 1
      }
    }
    do { try realm.commitWrite()} catch {fatalError()}
    print("save path: \(realm.configuration.fileURL!)")
    print("URLToMessage: saved \(messageCounter) message(s)")
  }
  
  private func saveMinMaxId(messages: [Message]) {
    //in case of refresh, we want to save overall new maxId
    //in case of focus or scrollup, we want to save the minimum id of the new messages
    let defaults = NSUserDefaults.standardUserDefaults()
    
    //the minimumId of the last message saved
    let currentMinId = messages[0].id
    
    //the maximumId of hte last message saved
    let currentMaxId = messages.last!.id
    
    //if we are narrowed, save minimumID of that narrow
    if let narrowString = action.narrow.narrowString {
      let defaultNarrowMinId = defaults.objectForKey(narrowString)
      if defaultNarrowMinId == nil || currentMinId < (defaultNarrowMinId as! Int) {
        defaults.setInteger(currentMinId, forKey: narrowString)
        print("URLToMessage: new minId - \(narrowString): \(currentMinId)")
      }
    }
      
    //if we're not narrowed, save to streamMin
    else {
      let defaultHomeMinId = defaults.objectForKey("homeMin")
      if defaultHomeMinId == nil || currentMinId < (defaultHomeMinId as! Int) {
        defaults.setInteger(currentMinId, forKey: "homeMin")
        print("URLToMessage: new homeMin - \(currentMinId)")
      }
    }
    
    let defaultMaxId = defaults.objectForKey("homeMax")
      if defaultMaxId == nil || currentMaxId > (defaultMaxId as! Int) {
      defaults.setInteger(currentMaxId, forKey: "homeMax")
        print("URLToMessage: new homeMax -  \(currentMaxId)")
    }
  }
}




