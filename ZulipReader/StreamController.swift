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
  
  func showHideNotification(type: Notification)
}

protocol SubscriptionDelegate: class {
  func didFetchSubscriptions(subscriptions: [String: String])
}

//TODO: rethink these queues.
class Queue {
  lazy var refreshNetworkQueue: NSOperationQueue = {
    var queue = NSOperationQueue()
    queue.name = "refreshNetworkQueue"
    queue.maxConcurrentOperationCount = 1
    return queue
  }()
  
  lazy var userNetworkQueue: NSOperationQueue = {
    var queue = NSOperationQueue()
    queue.name = "userNetworkQueue"
    queue.maxConcurrentOperationCount = 1
    return queue
  }()
  
  lazy var prepQueue: NSOperationQueue = {
    var queue = NSOperationQueue()
    queue.name = "prepQueue"
    queue.maxConcurrentOperationCount = 1
    return queue
  }()
  
  func cancelAll() {
    refreshNetworkQueue.cancelAllOperations()
    userNetworkQueue.cancelAllOperations()
    prepQueue.cancelAllOperations()
  }
}

class StreamController {
  
  weak var delegate: StreamControllerDelegate?
  weak var subscriptionDelegate: SubscriptionDelegate?
  
  private let realm: Realm
  private var subscription: [String:String] = [:]
  private var oldTableCells = [[TableCell]]()
  private var timer = NSTimer()
  private let queue = Queue()
  
  private var streamMinId = [String: Int]()
  private var refreshedMessageIds = Set<Int>()
  
  //we make this an instance variable beacause refresh needs to be aware of narrow
  private var action = Action()
  
  init() {
    do {
      realm = try Realm()
    } catch let error as NSError {
      fatalError(String(error))
    }
    //FOR DEBUGGING PURPOSES
//    clearDefaults()
  }
  
  func isLoggedIn() -> Bool {
    if let basicAuth = Locksmith.loadDataForUserAccount("default"),
      let authHead = basicAuth["Authorization"] as? String {
      Router.basicAuth = authHead
      
      self.timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(refreshData), userInfo: nil, repeats: true)
      
      return true
    }
    return false
  }
  
  private func resetTimer() {
    self.timer.invalidate()
    self.timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(refreshData), userInfo: nil, repeats: true)
  }
  
  //TODO: why do I need @objc?
  //new messages are loaded on refreshQueue, called by timer
  @objc private func refreshData() {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
      //we don't refresh until there's something to refresh
      if !self.oldTableCells.isEmpty {
        print("\n===refreshData===")
        //a generic action is used so we don't miss any new messages
        self.action.userAction = .Refresh
        var localAction = Action()
        localAction.userAction = .Refresh
        let messagesFromNetworkOperation = self.messagesFromNetwork(localAction)
        self.queue.refreshNetworkQueue.addOperation(messagesFromNetworkOperation)
      }
    }
  }
  
  func clearDefaults() {
    timer.invalidate()
    for key in NSUserDefaults.standardUserDefaults().dictionaryRepresentation().keys {
      NSUserDefaults.standardUserDefaults().removeObjectForKey(key)
    }
    do {
      try realm.write {
        print("clearDefaults: deleting realm")
        realm.deleteAll()
      }
    }
    catch{print("could not clear realm")}
    print("clearDefaults: deleting keychain")
    do {
      try Locksmith.deleteDataForUserAccount("default")
    }
    catch {print("unable to clear locksmith")}
    Router.basicAuth = nil
  }
  
  func register() {
    let registration = RegistrationOperation()
    registration.completionBlock = {
      dispatch_async(dispatch_get_main_queue()) {
        let registrationResults = registration.getSubscriptionAndMaxID()
        self.subscription = registrationResults.0
        NSUserDefaults.standardUserDefaults().setInteger(registrationResults.1, forKey: "homeMax")
        self.subscriptionDelegate?.didFetchSubscriptions(self.subscription)
        self.loadStreamMessages(Action())
      }
    }
    queue.userNetworkQueue.addOperation(registration)
  }
  
  //MARK: Post Messages
  private func createPostRequest(message: MessagePost) -> Future<URLRequestConvertible, ZulipErrorDomain> {
    let recipient: String
    if message.type == .Private {
      recipient = message.recipient.joinWithSeparator(",")
    } else {
      recipient = message.recipient[0]
    }
    let urlRequest: URLRequestConvertible = Router.PostMessage(type: message.type.description, content: message.content, to: recipient, subject: message.subject)
    return Future<URLRequestConvertible, ZulipErrorDomain>(value: urlRequest)
  }
  
  func postMessage(message: MessagePost, action: Action) {
    self.action = action
    createPostRequest(message)
      .andThen(AlamofireRequest)
      .start {result in
        switch result {
          
        case .Success(_):
          //generic refresh action
          self.refreshData()
          
        case .Error(let boxedError):
          let error = boxedError.unbox
          print("PostMessage: \(error)")
        }
    }
  }
  
  private func messagesFromNetwork(action: Action) -> NSOperation {
    let urlToMessagesArray = URLToMessageArray(action: action, subscription: self.subscription)
    urlToMessagesArray.delegate = self
    return urlToMessagesArray
  }
  
  private func tableCellsFromRealm(action: Action, isLast: Bool) -> NSOperation {
    let messageArrayToTableCellArray = MessageArrayToTableCellArray(action: action, oldTableCells: self.oldTableCells, isLast: isLast)
    messageArrayToTableCellArray.delegate = self
    return messageArrayToTableCellArray
  }
  
  var loading = false
  
  //MARK: Get Stream Messages
  func loadStreamMessages(action: Action) {
    print("\n==== NEW MSG LOAD ====")
    if self.loading {
      return
    }
    self.loading = true
    self.action = action
    
    //cancel previous operations when user makes a new request
    self.queue.cancelAll()
    self.resetTimer()
    let tableCellsFromRealmOperation = self.tableCellsFromRealm(action, isLast: false)
    self.queue.prepQueue.addOperation(tableCellsFromRealmOperation)
  }
}

//MARK: URLToMessagesArrayDelegate
extension StreamController: URLToMessageArrayDelegate {
  internal func urlToMessageArrayDidFinish(messages: [Message], userAction: UserAction) {
    switch userAction {
    case .Refresh:
      //only load refreshed messages if there are new messages and there's no UI action
      
      //MARK: Notifications
      guard !messages.isEmpty else {return}
      
      for message in messages {
        self.refreshedMessageIds.insert(message.id)
      }
      
      let filteredMessages = NSArray(array: messages).filteredArrayUsingPredicate(action.narrow.predicate()) as! [Message]
      let messageIdIntersect = self.refreshedMessageIds.intersect(filteredMessages.map {$0.id})
      
      guard !messageIdIntersect.isEmpty else {return}
      
      for messageID in messageIdIntersect {
        self.refreshedMessageIds.remove(messageID)
      }
      
      if !self.refreshedMessageIds.isEmpty {
        dispatch_async(dispatch_get_main_queue()){
          self.delegate?.showHideNotification(.Badge)
        }
      }
      
      //only load new message notification and new table cells if there's no other user input
      guard self.queue.prepQueue.operationCount == 0 && self.queue.userNetworkQueue.operationCount == 0 else {return}
  
      dispatch_async(dispatch_get_main_queue()){
        self.delegate?.showHideNotification(.NewMessage)
      }
      
    default:
      guard !messages.isEmpty else {
        dispatch_async(dispatch_get_main_queue()){
          self.delegate?.didFetchMessages()
        }
        self.loading = false
        return
      }
    }
    
    print("adding tableCellsFromRealmOperation")
    let tableCellsFromRealmOperation = self.tableCellsFromRealm(self.action, isLast: true)
    self.queue.prepQueue.addOperation(tableCellsFromRealmOperation)
  }
}

//MARK: MessagesArrayToTableCellArrayDelegate
extension StreamController: MessageArrayToTableCellArrayDelegate {
  func messageToTableCellArrayDidFinish(tableCells: [[TableCell]], deletedSections: NSRange, insertedSections: NSRange, insertedRows: [NSIndexPath]) {
    self.loading = false
    
    if insertedRows.isEmpty {
      //The following statements run iff isLast = true
      print("TableCell Delegate: insertedRows is empty")
      dispatch_async(dispatch_get_main_queue()) {
        self.delegate?.didFetchMessages()
        return
      }
    }
    else {
      //oldTableCells is only reassigned if new messages are loaded
      self.oldTableCells = tableCells
      print("TableCell Delegate: TC's to TableView")
      
      dispatch_async(dispatch_get_main_queue()) {
        self.delegate?.didFetchMessages(tableCells, deletedSections: deletedSections, insertedSections: insertedSections, insertedRows: insertedRows)
      }
    }
  }
  
  func realmNeedsMoreMessages() {
    let messagesFromNetworkOperation = self.messagesFromNetwork(self.action)
    self.queue.userNetworkQueue.addOperation(messagesFromNetworkOperation)
  }
}

