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
        self.complete()
        return
      }
      
      switch result {
      case .Success(let box):
        self.messages = box.unbox
        if !self.messages.isEmpty {
          self.messagesToRealm(self.messages)
          self.saveMinMaxId(self.messages)
          
          if self.cancelled {
            self.complete()
            return
          }
          
          self.delegate?.urlToMessageArrayDidFinish(self.messages, userAction: self.action.userAction)
        }
        print("URLToMessageArray Completed")
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
    
    //after #'s are comically large to make sure we don't miss any messages. They also don't seem to have any noticeable performance impact.
    //in v2 - we should add checks to load more messages if new messages exceeds after. For now, 20k should do...
    switch action.userAction {
    case .Focus:
      params = MessageRequestParameters(anchor: maxAnchor, before: 50, after: 20000, narrow: action.narrow.narrowString)
    case .Refresh:
      params = MessageRequestParameters(anchor: maxAnchor+1, before: 0, after: 20000, narrow: action.narrow.narrowString)
    case .ScrollUp:
      params = MessageRequestParameters(anchor: minAnchor, before: 50, after: 0, narrow: action.narrow.narrowString)
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
        
        msg.content = self.processEmoji(msg.content)
        
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
  
  private func processEmoji(text: String) -> String {
    //translated most of this from the original Zulip ios project
    guard text.rangeOfString("static/third/gemoji/images/emoji") != nil else {return text}
    
    var emojiRegex: NSRegularExpression {
      do {
        return try NSRegularExpression(pattern: "<img alt=\":([^:]+):\" class=\"emoji\" src=\"static/third/gemoji/images/emoji/[^.]+.png+\" title=\":[^:]+:\">", options: NSRegularExpressionOptions.CaseInsensitive)
      }
      catch let error as NSError {
        print("\n\n regex error: \(error) \n\n")
        return NSRegularExpression()
      }
    }
    
    let matches = emojiRegex.matchesInString(text, options: NSMatchingOptions.init(rawValue: 0), range: NSMakeRange(0, text.characters.count))
    
    let textCopy = NSMutableString(string: text)
    
    var offset = 0
    for match in matches {
      var range = match.range
      range.location += offset
      
      let emojiString = ":" + emojiRegex.replacementStringForResult(match, inString: textCopy as String, offset: offset, template: "$1") + ":"
      
      let utfEmoji: String
      if let emoji = EMOJI_HASH[emojiString] {
        utfEmoji = emoji
      } else {
        utfEmoji = emojiString
      }
      
      //NSMutableString(utfEmoji).count = 2; String(emoji).character.count = 1
      textCopy.replaceCharactersInRange(range, withString: utfEmoji)
      offset += NSMutableString(string: utfEmoji).length - range.length
    }
    return textCopy as String
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
      if !currentMessageID.contains(message.id) {
        realm.create(Message.self, value: message)
        messageCounter += 1
      }
    }
    do { try realm.commitWrite()} catch {fatalError()}
    print("save path: \(realm.path)")
    print("URLToMessage: saved \(messageCounter) message(s)")
  }
  
  private func saveMinMaxId(messages: [Message]) {
    let defaults = NSUserDefaults.standardUserDefaults()
    let currentMinId = messages[0].id
    let currentMaxId = messages.last!.id
    
    if let narrowString = action.narrow.narrowString {
      let defaultNarrowMinId = defaults.objectForKey(narrowString)
      if defaultNarrowMinId == nil || currentMinId < (defaultNarrowMinId as! Int) {
        defaults.setInteger(currentMinId, forKey: narrowString)
        print("URLToMessage: new minId - \(narrowString): \(currentMinId)")
      }
    }
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




