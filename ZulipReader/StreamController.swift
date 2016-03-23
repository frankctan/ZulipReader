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
  func didFetchMessages(messages: [[TableCell]], deletedSections: NSRange, insertedSections: NSRange, insertedRows: [NSIndexPath])
  func didFetchMessages()
}

protocol SubscriptionDelegate: class {
  func didFetchSubscriptions(subscriptions: [String: String])
}

class Queue {
  lazy var realmToMessageArray: NSOperationQueue = {
    var queue = NSOperationQueue()
    queue.name = "Realm To Message Array"
    queue.maxConcurrentOperationCount = 1
    return queue
  }()
  
  lazy var messageToTableCell: NSOperationQueue = {
    var queue = NSOperationQueue()
    queue.name = "Message To Table Cell"
    queue.maxConcurrentOperationCount = 1
    return queue
  }()
}


class StreamController: URLToMessageArrayDelegate, MessageArrayToTableCellArrayDelegate {
  
  weak var delegate: StreamControllerDelegate?
  weak var subscriptionDelegate: SubscriptionDelegate?
  
  private let realm: Realm
  private var subscription: [String:String] = [:]
  private var registration = Registration()
  private var oldTableCells = [[TableCell]]()
  
  private var homeMessageRange = (Int.max, Int.min)
  private var streamMessageRange = [String: (Int, Int)]()
  
  init() {
    do {
      realm = try Realm()
    } catch let error as NSError {
      fatalError(String(error))
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
    do {
      try realm.write {
        print("deleting realm")
        realm.deleteAll()
      }
    }
    catch{print("could not clear realm")}
    print("deleting keychain")
    do {
      try Locksmith.deleteDataForUserAccount("default")
    }
    catch {print("unable to clear locksmith")}
    Router.basicAuth = nil
    NSUserDefaults.standardUserDefaults().removeObjectForKey("email")
  }
  
  //MARK: Post Messages
  func createPostRequest(message: MessagePost) -> Future<URLRequestConvertible, ZulipErrorDomain> {
    let recipient: String
    if message.type == .Private {
      recipient = message.recipient.joinWithSeparator(",")
    } else {
      recipient = message.recipient[0]
    }
    
    print("post url request:")
    let urlRequest: URLRequestConvertible = Router.PostMessage(type: message.type.description, content: message.content, to: recipient, subject: message.subject)
    return Future<URLRequestConvertible, ZulipErrorDomain>(value: urlRequest)
  }
  
  func postMessage(message: MessagePost, action: Action) {
    createPostRequest(message)
      .andThen(AlamofireRequest)
      .start {result in
        switch result {
        case .Success(_):
          self.loadStreamMessages(action)
        case .Error(let boxedError):
          let error = boxedError.unbox
          print(error)
        }
    }
  }
  
  let queue = Queue()
  //MARK: Get Stream Messages
  func loadStreamMessages(action: Action) {
    print("loading Stream Messages")
    print("action: \(action.userAction)")
    
    //TODO: Need to reference the dictionary.
    if !oldTableCells.isEmpty {
      let loadMessagesFromRealmOperation = MessageArrayToTableCellArray(action: action, newMessages: [], oldTableCells: oldTableCells)
      loadMessagesFromRealmOperation.delegate = self
      queue.messageToTableCell.addOperation(loadMessagesFromRealmOperation)
    }
    
    let operation = URLToMessageArray(action: action, subscription: self.subscription, registrationMax: self.registration.maxMessageID, homeMessageRange: self.homeMessageRange, streamMessageRange: self.streamMessageRange)
    operation.delegate = self
    queue.messageToTableCell.addOperation(operation)
  }
  
  //MARK: URLToMessagesArrayDelegate
  func messageArraysDidFinish(action: Action, newMessages: [Message]) {
    dispatch_async(dispatch_get_main_queue()) {
      if newMessages.isEmpty {
        self.delegate?.didFetchMessages()
        return
      }
      //update message markers
      self.writeMinMaxID(action, minMessageID: newMessages[0].id, maxMessageID: newMessages.last!.id)
      let action = self.readMinMaxID(action)
      
      let operation = MessageArrayToTableCellArray(action: action, newMessages: newMessages, oldTableCells: self.oldTableCells)
      operation.delegate = self
      self.queue.messageToTableCell.addOperation(operation)
    }
  }
  
  //MARL: MessageArrayToTableCellArrayDelegate
  func tableCellsDidFinish(deletedSections: NSRange, insertedSections: NSRange, insertedRows: [NSIndexPath], tableCells: [[TableCell]]) {
    dispatch_async(dispatch_get_main_queue()) {
      if tableCells[0].isEmpty {
        return
      }
      self.delegate?.didFetchMessages(tableCells, deletedSections: deletedSections, insertedSections: insertedSections, insertedRows: insertedRows)
      self.oldTableCells = tableCells
      print("tableCellsDidFinish")
    }
  }
  
  private func readMinMaxID(action: Action) -> Action {
    var returnAction = action
    //checks home or narrowed topic
    if let narrowString = action.narrow.narrowString {
      //checks if first time being narrowed to
      if let messageRange = self.streamMessageRange[narrowString] {
        let minID = messageRange.0
        let maxID = messageRange.1
        returnAction.narrow.setMinMaxID(minID, maxID: maxID)
      }
      else {
        returnAction.narrow.setMinMaxID(Int.max, maxID: Int.min)
      }
    }
    else {
      returnAction.narrow.setMinMaxID(self.homeMessageRange.0, maxID: self.homeMessageRange.1)
    }
    return returnAction
  }

  private func writeMinMaxID(action: Action, minMessageID: Int, maxMessageID: Int) {
    if let narrowString = action.narrow.narrowString {
      if let messageRange = self.streamMessageRange[narrowString] {
        self.streamMessageRange[narrowString] = (min(messageRange.0, minMessageID), max(messageRange.1, maxMessageID))
      }
        else {
          self.streamMessageRange[narrowString] = (minMessageID, maxMessageID)
        }
    }
    else {
      self.homeMessageRange = (min(self.homeMessageRange.0, minMessageID), max(self.homeMessageRange.1, maxMessageID))
    }
  }
  
  //MARK: Register
  
  private struct Registration {
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
  
  func register() {
    registrationPipeline()
      .start { result in
        switch result {
          
        case .Success(let boxedReg):
          let reg = boxedReg.unbox
          self.recordRegistration(reg)
          self.loadStreamMessages(Action(narrow: Narrow(), action: .Focus))
          
        case .Error(let boxedError):
          let error = boxedError.unbox
          print("registration error: \(error)")
        }
    }
  }
  
  private func registrationPipeline() -> Future<Registration, ZulipErrorDomain> {
    return createRegistrationRequest()
      .andThen(AlamofireRequest)
      .andThen(getStreamAndAchor)
  }
  
  private func createRegistrationRequest() -> Future<URLRequestConvertible, ZulipErrorDomain> {
    let urlRequest = Router.Register
    return Future<URLRequestConvertible, ZulipErrorDomain>(value: urlRequest)
  }
  
  private func getStreamAndAchor(response: JSON) -> Future<Registration, ZulipErrorDomain> {
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
  
  //writes subscription dictionary, realm persistence, sends subscription colors to sideMenuDelegate
  private func recordRegistration(registration: Registration) {
    print("registration saved")
    for sub in registration.subscription {
      self.subscription[sub["name"].stringValue] = sub["color"].stringValue
    }
    self.subscriptionDelegate?.didFetchSubscriptions(self.subscription)
    subscriptionsToRealm(registration.subscription)
    self.registration = registration
  }
  
  private func subscriptionsToRealm(subscriptions: [JSON]) {
    print("writing subscriptions")
//    print("save path: \(realm.path)")
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
}