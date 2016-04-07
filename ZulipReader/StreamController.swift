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

//TODO: rethink these queues.
class Queue {
  lazy var refreshQueue: NSOperationQueue = {
    var queue = NSOperationQueue()
    queue.name = "refreshQueue"
    queue.maxConcurrentOperationCount = 1
    return queue
  }()
  
  lazy var messageQueue: NSOperationQueue = {
    var queue = NSOperationQueue()
    queue.name = "messageQueue"
    queue.maxConcurrentOperationCount = 1
    return queue
  }()
}

class StreamController {
  
  weak var delegate: StreamControllerDelegate?
  weak var subscriptionDelegate: SubscriptionDelegate?
  
  private let realm: Realm
  private var subscription: [String:String] = [:]
  private var oldTableCells = [[TableCell]]()
  private var timer = NSTimer()
  
  private var maxId = Int.min
  private var homeMinId = Int.max
  private var streamMinId = [String: Int]()
  private var realmNotification = NotificationToken()
  
  //we make this an instance variable beacause refresh needs to be aware of narrow
  private var action = Action()
  
  init() {
    do {
      realm = try Realm()
    } catch let error as NSError {
      fatalError(String(error))
    }
    self.realmNotification = realm.objects(Message).addNotificationBlock {result, _ in
      if let result = result where result.count > 0 {
        print("realmNotificationBlock")
        let tableCellsFromRealmOperation = self.tableCellsFromRealm(self.action)
        self.queue.messageQueue.addOperation(tableCellsFromRealmOperation)
      }
    }
    //FOR DEBUGGING PURPOSES
//    clearDefaults()
  }
  
  func isLoggedIn() -> Bool {
    if let basicAuth = Locksmith.loadDataForUserAccount("default"),
      let authHead = basicAuth["Authorization"] as? String {
      Router.basicAuth = authHead
      
      //      self.timer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(self.refreshData(_:)), userInfo: nil, repeats: true)
      return true
    }
    return false
  }
  
  //TODO: why do I need @objc?
  //TODO: put autorefresh networking onto a different queue, use a generic local variable. Always load messages from Realm from the Action instance variable
  @objc private func refreshData(timer: NSTimer) {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
      if !self.oldTableCells.isEmpty {
        print("refreshData:")
        self.refreshStreamMessages(Action())
      }
    }
  }
  
  private func refreshStreamMessages(localAction: Action) {
//    let messagesFromNetworkOperation = self.messagesFromNetwork(localAction)
//    messagesFromNetworkOperation.completionBlock = {
//      self.action.userAction = .Refresh
//      let tableCellsFromRealmOperation = self.tableCellsFromRealm(self.action)
//      self.queue.refreshQueue.addOperation(tableCellsFromRealmOperation)
//    }
//    self.queue.refreshQueue.addOperation(messagesFromNetworkOperation)
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
    queue.messageQueue.addOperation(registration)
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
          self.loadStreamMessages(action)
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
  
  private func tableCellsFromRealm(action: Action) -> NSOperation {
    let messageArrayToTableCellArray = MessageArrayToTableCellArray(action: action, oldTableCells: self.oldTableCells)
    messageArrayToTableCellArray.delegate = self
    return messageArrayToTableCellArray
  }
  
  let queue = Queue()
  //MARK: Get Stream Messages
  func loadStreamMessages(action: Action) {
    print("\n==== NEW MSG LOAD ====")
    self.action = action
    let tableCellsFromRealmOperation = self.tableCellsFromRealm(action)
    self.queue.messageQueue.addOperation(tableCellsFromRealmOperation)
  }
}

//MARK: URLToMessagesArrayDelegate
extension StreamController: URLToMessageArrayDelegate {
  internal func urlToMessageArrayDidFinish(action: Action, messages: [Message]) {
    if messages.isEmpty {
      dispatch_async(dispatch_get_main_queue()){
        self.delegate?.didFetchMessages()
      }
    }
  }
}

//MARK: MessagesArrayToTableCellArrayDelegate
extension StreamController: MessageArrayToTableCellArrayDelegate {
  func messageToTableCellArrayDidFinish(tableCells: [[TableCell]], deletedSections: NSRange, insertedSections: NSRange, insertedRows: [NSIndexPath]) {
    
    //double check if there are new messages
    if insertedRows.isEmpty {
      print("TableCell Delegate: insertedRows is empty")
      dispatch_async(dispatch_get_main_queue()) {
        self.delegate?.didFetchMessages()
        return
      }
    }
    else {
      self.oldTableCells = tableCells
      print("TableCell Delegate: TC's to TableView")
      dispatch_async(dispatch_get_main_queue()) {
        self.delegate?.didFetchMessages(tableCells, deletedSections: deletedSections, insertedSections: insertedSections, insertedRows: insertedRows)
      }
    }
  }
  
  func realmNeedsMoreMessages() {
    let messagesFromNetworkOperation = self.messagesFromNetwork(self.action)
    self.queue.messageQueue.addOperation(messagesFromNetworkOperation)
  }
}

