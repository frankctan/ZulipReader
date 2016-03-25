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


class StreamController: URLToMessageArrayDelegate {
  
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
        self.subscriptionDelegate?.didFetchSubscriptions(self.subscription)
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
    urlToMessagesArray.delegate = self
    return urlToMessagesArray
  }
  
  //MARK: URLToMessagesArrayDelegate
  func urlToMessageArrayDidFinish(action: Action, messages: [Message]) {
    print("in URLToMessagesArrayDelegate!")
    self.saveMinMaxId(action, newMessages: messages)
    dispatch_async(dispatch_get_main_queue()){
      if messages.isEmpty {
        self.delegate?.didFetchMessages()
        return
      }
    }
  }
  
  func tableCellsFromRealm(action: Action) -> NSOperation {
    //setActionMinMaxId(_:) modifies narrow.min/max ID
    let action = setActionMinMaxId(action)
    let messageArrayToTableCellArray = MessageArrayToTableCellArray(action: action, oldTableCells: self.oldTableCells)
    messageArrayToTableCellArray.completionBlock = {
      let (tableCells, deletedSections, insertedSections, insertedRows) = messageArrayToTableCellArray.getTableCells()
      self.oldTableCells = tableCells
      dispatch_async(dispatch_get_main_queue()) {
        if insertedRows.isEmpty {
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
    let messagesFromNetworkOperation = self.messagesFromNetwork(action)
    
    messagesFromNetworkOperation.completionBlock = {
      let tableCellsFromRealmOperation = self.tableCellsFromRealm(action)
      self.queue.messageToTableCell.addOperation(tableCellsFromRealmOperation)
    }
    
    queue.messageToTableCell.addOperation(messagesFromNetworkOperation)
  }
  
  private func setActionMinMaxId(action: Action) -> Action {
    var returnAction = action
    let minId: Int
    
    if let narrowString = action.narrow.narrowString {
      if let streamMinId = self.streamMinId[narrowString] { minId = streamMinId }
      else { minId = self.homeMinId }
    }
    else { minId = self.homeMinId }
    
    returnAction.narrow.setMinMaxID(minId, maxID: self.maxId)
    
    return returnAction
  }

  private func saveMinMaxId(action: Action, newMessages: [Message]) {
    let minMessageId = newMessages[0].id
    let maxMessageId = newMessages.last!.id
    
    if maxMessageId > self.maxId {
      print("self.maxId has increased!")
    }
    self.maxId = max(self.maxId, maxMessageId)

    if let narrowString = action.narrow.narrowString {
      if let minId = self.streamMinId[narrowString] {
        self.streamMinId[narrowString] = min(minId, minMessageId)
      }
        else {
          self.streamMinId[narrowString] = minMessageId
        }
      print("streamMinId: \(self.streamMinId)")
    }
    else {
      self.homeMinId = min(homeMinId, minMessageId)
      print("homeMindId: \(self.homeMinId)")
    }
    print("saved minMaxId!")
  }
}