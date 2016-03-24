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


class StreamController {
  
  weak var delegate: StreamControllerDelegate?
  weak var subscriptionDelegate: SubscriptionDelegate?
  
  private let realm: Realm
  private var subscription: [String:String] = [:]
  private var oldTableCells = [[TableCell]]()
  
  private var maxId = Int.min
  private var homeMinId = Int.max
  private var streamMinId = [String: Int]()
  
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
  
  func register() {
    print("registering")
    let registration = RegistrationOperation()
    registration.completionBlock = {
      dispatch_async(dispatch_get_main_queue()) {
        let registrationResults = registration.getSubscriptionAndMaxID()
        self.subscription = registrationResults.0
        self.maxId = max(self.maxId, registrationResults.1)
        print("finished registration: \(self.maxId)")
        self.loadStreamMessages(Action())
      }
    }
    queue.messageToTableCell.addOperation(registration)
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
  
  func messagesFromNetwork(action: Action) -> NSOperation {
    let urlToMessagesArray = URLToMessageArray(action: action, subscription: self.subscription, maxId: self.maxId, homeMinId: self.homeMinId, streamMinId: self.streamMinId)
    urlToMessagesArray.completionBlock = {
      let newMessages = urlToMessagesArray.getNewMessages()
      dispatch_async(dispatch_get_main_queue()){
        if newMessages.isEmpty {
          self.delegate?.didFetchMessages()
          return
        }
        self.saveMinMaxId(action, newMessages: newMessages)
      }
    }
    return urlToMessagesArray
  }
  
  func tableCellsFromRealm(action: Action, newMessages: [Message]) -> NSOperation {
    let action = setActionMinMaxId(action)
    let messageArrayToTableCellArray = MessageArrayToTableCellArray(action: action, newMessages: newMessages, oldTableCells: self.oldTableCells)
    messageArrayToTableCellArray.completionBlock = {
      dispatch_async(dispatch_get_main_queue()) {
        let (tableCells, deletedSections, insertedSections, insertedRows) = messageArrayToTableCellArray.getTableCells()
        if tableCells[0].isEmpty {
          self.delegate?.didFetchMessages()
          return
        }
        self.delegate?.didFetchMessages(tableCells, deletedSections: deletedSections, insertedSections: insertedSections, insertedRows: insertedRows)
        self.oldTableCells = tableCells
      }
    }
    return messageArrayToTableCellArray
  }
  
  let queue = Queue()
  //MARK: Get Stream Messages
  func loadStreamMessages(action: Action) {
    let messagesFromNetworkOperation = self.messagesFromNetwork(action)
    let tableCellsFromRealmOperation = self.tableCellsFromRealm(action, newMessages: <#T##[Message]#>)
    
  }
  
  private func setActionMinMaxId(action: Action) -> Action {
    var returnAction = action
    let minId: Int
    
    if let narrowString = action.narrow.narrowString {
      if let streamMinId = self.streamMinId[narrowString] { minId = streamMinId }
      else { minId = Int.max }
    }
    else { minId = self.homeMinId }
    
    returnAction.narrow.setMinMaxID(minId, maxID: self.maxId)
    
    return returnAction
  }

  private func saveMinMaxId(action: Action, newMessages: [Message]) {
    let minMessageId = newMessages[0].id
    let maxMessageId = newMessages.last!.id
    if let narrowString = action.narrow.narrowString {
      if let minId = self.streamMinId[narrowString] {
        self.streamMinId[narrowString] = min(minId, minMessageId)
      }
        else {
          self.streamMinId[narrowString] = minMessageId
        }
    }
    else {
      self.homeMinId = min(homeMinId, minMessageId)
      self.maxId = max(self.maxId, maxMessageId)
    }
  }
}