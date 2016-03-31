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

class StreamController: URLToMessageArrayDelegate {
  
  weak var delegate: StreamControllerDelegate?
  weak var subscriptionDelegate: SubscriptionDelegate?
  
  private let realm: Realm
  private var subscription: [String:String] = [:]
  private var oldTableCells = [[TableCell]]()
  
  private var timer = NSTimer()
  
  private var maxId = Int.min
  private var homeMinId = Int.max
  private var streamMinId = [String: Int]()
  
  //we make this an instance variable beacause refresh needs to be aware of narrow
  private var action = Action()
  
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
      self.timer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(self.refreshData(_:)), userInfo: nil, repeats: true)
        return true
    }
    return false
  }
  
  //TODO: why do I need @objc?
  //TODO: put autorefresh networking onto a different queue, use a generic local variable. Always load messages from Realm from the Action instance variable
  @objc private func refreshData(timer: NSTimer) {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
      if !self.oldTableCells.isEmpty {
        print("shots fired!")
        self.action.userAction = .Refresh
        self.loadStreamMessages(self.action)
      }
    }
  }
  
  func clearDefaults() {
    timer.invalidate()
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
    queue.messageToTableCell.addOperation(registration)
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
          print(error)
        }
    }
  }
  
  private func messagesFromNetwork(action: Action) -> NSOperation {
    let urlToMessagesArray = URLToMessageArray(action: action, subscription: self.subscription)
    urlToMessagesArray.delegate = self
    return urlToMessagesArray
  }
  
  //MARK: URLToMessagesArrayDelegate
  internal func urlToMessageArrayDidFinish(action: Action, messages: [Message]) {
    print("in URLToMessagesArrayDelegate!")
    if messages.isEmpty {
      dispatch_async(dispatch_get_main_queue()){
        //no new messages? pause activity indicators
        self.delegate?.didFetchMessages()
      }
    }
  }
  
  private func tableCellsFromRealm(action: Action) -> NSOperation {
    let messageArrayToTableCellArray = MessageArrayToTableCellArray(action: action, oldTableCells: self.oldTableCells)
    messageArrayToTableCellArray.completionBlock = {
      let (tableCells, deletedSections, insertedSections, insertedRows) = messageArrayToTableCellArray.getTableCells()
      self.oldTableCells = tableCells
      dispatch_async(dispatch_get_main_queue()) {
        if insertedRows.isEmpty {
          //no new messages? pause activity indicators
          self.delegate?.didFetchMessages()
          return
        }
        print("table Cells From Realm - Sending to controller!")
        self.delegate?.didFetchMessages(tableCells, deletedSections: deletedSections, insertedSections: insertedSections, insertedRows: insertedRows)
      }
    }
    return messageArrayToTableCellArray
  }
  
  let queue = Queue()
  //MARK: Get Stream Messages
  func loadStreamMessages(action: Action) {
    self.action = action
    let messagesFromNetworkOperation = self.messagesFromNetwork(action)
    
    messagesFromNetworkOperation.completionBlock = {
      let tableCellsFromRealmOperation = self.tableCellsFromRealm(action)
      self.queue.messageToTableCell.addOperation(tableCellsFromRealmOperation)
    }
    
    queue.messageToTableCell.addOperation(messagesFromNetworkOperation)
  }
}