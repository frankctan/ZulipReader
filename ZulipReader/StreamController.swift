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

class StreamController : DataController {
  
  weak var delegate: StreamControllerDelegate?
  
  private let realm: Realm
  private var subscription: [String:String] = [:]
  private var registration = Registration()
  private var oldTableCells = [[TableCell]]()
  private var minimumStreamMessageID = Int.max
  private var minimumSubMessageID = [String: Int]()
  
  override init() {
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
    Router.basicAuth = nil
    NSUserDefaults.standardUserDefaults().removeObjectForKey("email")
    //    realm.deleteAll()
    do {
      try Locksmith.deleteDataForUserAccount("default")
    }
    catch {print("locksmith already cleared")}
  }
  
  //MARK: Get Stream Messages
  var loading = false
  
  func loadStreamMessages(action: Action) {
    //no double loading
    if loading {
      return
    }
    loading = true
    print("loading Stream Messages")
    print("action: \(action.userAction)")
    
    var action = action
    
    //Read minimum pointer for each sub
    if let narrowString = action.narrow.narrowString {
      if let currentPointer = self.minimumSubMessageID[narrowString] {
        action.narrow.minimumMessageID = currentPointer
      }
      else {
        action.narrow.minimumMessageID = Int.max
      }
    }
    else {
      action.narrow.minimumMessageID = self.minimumStreamMessageID
    }
    
    switch action.userAction {
    case .Focus:
      let _realmMessages: NSArray = self.realm.objects(Message).sorted("timestamp", ascending: true).map {$0}
      let realmMessages = _realmMessages.filteredArrayUsingPredicate(action.narrow.predicate()) as! [Message]
      if !realmMessages.isEmpty {
        self.messagesToController(realmMessages, newMessages: realmMessages, action: action.userAction)
        action.userAction = .Refresh
      }
    default: break
    }
    
    print("action: \(action.userAction)")
    let params = self.createRequestParameters(action)
    self.messagePipeline(params)
      .start {result in
        print("results from message pipeline!")
        switch result {
          
        case .Success(let boxedMessages):
          let messages = boxedMessages.unbox
          if !messages.isEmpty {

            let newMessages: [Message] = messages
            self.messagesToRealm(newMessages)
            let _realmMessages: NSArray = self.realm.objects(Message).sorted("timestamp", ascending: true).map {$0}
            
            //set minimumStreamMessageID if messages aren't narrowed
            let currentMessagesMinimumID = newMessages[0].id
            if let narrowString = action.narrow.narrowString {
              if let currentPointer = self.minimumSubMessageID[narrowString] {
                self.minimumSubMessageID[narrowString] = min(currentPointer, currentMessagesMinimumID)
              }
              else {
                self.minimumSubMessageID[narrowString] = currentMessagesMinimumID
              }
              action.narrow.minimumMessageID = self.minimumSubMessageID[narrowString]!
            }
            else {
              self.minimumStreamMessageID = min(self.minimumStreamMessageID, currentMessagesMinimumID)
              action.narrow.minimumMessageID = self.minimumStreamMessageID
            }
            
            let realmMessages:[Message] = _realmMessages.filteredArrayUsingPredicate(action.narrow.predicate()) as! [Message]
            self.messagesToController(realmMessages, newMessages: newMessages, action: action.userAction)
          }
          else {
            self.delegate?.didFetchMessages()
          }
          
        case .Error(let error):
          print(error.unbox.description)
        }
        
        self.loading = false
    }
  }
  
  //only called if server sends new messages
  private func messagesToController(allMessages: [Message], newMessages: [Message], action: UserAction) {
    print("in messagesToController")
    let newTableCells = self.messageToTableCell(allMessages)
    let (deletedSections, insertedSections, insertedRows) = self.findTableUpdates(newTableCells, newMessages: newMessages, action: action)
    self.delegate?.didFetchMessages(newTableCells, deletedSections: deletedSections, insertedSections: insertedSections, insertedRows: insertedRows)
    self.oldTableCells = newTableCells
  }
  
  private func findTableUpdates(newTableCells: [[TableCell]], newMessages: [Message], action: UserAction) -> (deletedSections: NSRange, insertedSections: NSRange, insertedRows: [NSIndexPath]) {
    print("allMessages Section Count: \(newTableCells.count)")

    let newMessageTableCells = self.messageToTableCell(newMessages)
    
    print("newMessages Section Count: \(newMessageTableCells.count)")
    let flatNewMessageTableCells = newMessageTableCells.flatMap {$0}
    let flatOldTableCells = oldTableCells.flatMap {$0}
    
    var deletedSections = NSRange()
    var insertedSections = NSRange()
    var insertedRows = [NSIndexPath]()
    
    print("flatOld#: \(flatOldTableCells.count) + flatNew#: \(flatNewMessageTableCells.count) = newMessage#: \(newTableCells.reduce(0, combine: {$0 + $1.count}))")
    
    switch action {
    case .Focus:
      deletedSections = NSMakeRange(0, oldTableCells.count)
      insertedSections = NSMakeRange(0, newTableCells.count)
      insertedRows = flatNewMessageTableCells.map {NSIndexPath(forRow: $0.row, inSection: $0.section)}
      
    case .ScrollUp:
      insertedSections = NSMakeRange(0, newTableCells.count - oldTableCells.count)
      insertedRows = flatNewMessageTableCells.map {NSIndexPath(forRow: $0.row, inSection: $0.section)}
      
    case .Refresh:
      let lastOldTableCell = flatOldTableCells.last!
      let rangeLength = newTableCells.count - oldTableCells.count
      if rangeLength > 0 {
        insertedSections = NSMakeRange(lastOldTableCell.section + 1, rangeLength)
      }
      let newMessageCount = newMessages.count
      let flatNewTableCells = newTableCells.flatMap {$0}
      for index in (flatNewTableCells.count - newMessageCount)..<flatNewTableCells.count {
        insertedRows.append(NSIndexPath(forRow: flatNewTableCells[index].row, inSection: flatNewTableCells[index].section))
      }
    }
    
    return (deletedSections, insertedSections, insertedRows)
  }
  
  private func compareTableCells(tc1: TableCell, _ tc2: TableCell) -> Bool {
    if tc1.display_recipient == tc2.display_recipient && tc1.subject == tc2.subject {
      return true
    }
    return false
  }
  
  private func messagePipeline(params: MessageRequestParameters) -> Future<[Message], ZulipErrorDomain> {
    return createMessageRequest(params)
      .andThen(AlamofireRequest)
      .andThen(processResponse)
  }
  
  private func createRequestParameters(action: Action) -> MessageRequestParameters {
    var params = MessageRequestParameters()
    let (minAnchor, maxAnchor) = getAnchor()
    
    switch action.userAction {
    case .Focus:
      params = MessageRequestParameters(anchor: maxAnchor, before: 20, after: 50, narrow: action.narrow.narrowString)
    case .Refresh:
      params = MessageRequestParameters(anchor: maxAnchor, before: 0, after: 50, narrow: action.narrow.narrowString)
    case .ScrollUp:
      params = MessageRequestParameters(anchor: minAnchor, before: 20, after: 0, narrow: action.narrow.narrowString)
    }
    return params
  }
  
  private func getAnchor() -> (min: Int, max: Int) {
    let messages = oldTableCells.flatMap {$0}
    
    var realmMaxID = 0
    if let last = messages.last {
      realmMaxID = last.id
    }
    //registrationID used for first message load
    let registrationID = registration.maxMessageID
    
    //minID only used to scroll up
    var realmMinID = 0
    if let first = messages.first {
      realmMinID = first.id
    }
    //offset by 1 to reduce duplicates
    return (realmMinID-1, max(realmMaxID, registrationID)+1)
  }
  
  private func createMessageRequest(params: MessageRequestParameters) -> Future<URLRequestConvertible, ZulipErrorDomain> {
    let urlRequest: URLRequestConvertible = Router.GetMessages(anchor: params.numAnchor, before: params.numBefore, after: params.numAfter, narrow: params.narrow)
    return Future<URLRequestConvertible, ZulipErrorDomain>(value: urlRequest)
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
        
        //assigns streamColor
        if msg.type == "private", let privateRecipients = message["display_recipient"].array {
          msg.display_recipient = privateRecipients.map {$0["email"].stringValue}
          
          msg.privateFullName =
            privateRecipients
              .filter {if $0["email"].stringValue == ownEmail {return false}; return true}
              .map {$0["full_name"].stringValue}
          
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
  
  //checks for uniqueness based on dateTime, saves whether the message was obtained while narrowed
  private func messagesToRealm(messages: [Message]) {
    print("writing messages...")
    print("save path: \(realm.path)")
    let currentMessages = self.realm.objects(Message).sorted("timestamp", ascending: true).map {$0}
    let currentMessageTimeStamp = currentMessages.map {$0.dateTime}
    for message in messages {
      if !currentMessageTimeStamp.contains(message.dateTime) {
        do {
          try realm.write {
            realm.add(message)
          }
        } catch { fatalError("msgs: could not write to realm") }
      }
    }
    print("finished writing")
  }
  
  //MARK: Prepare messages for table view
  private func messageToTableCell(messages: [Message]) -> [[TableCell]] {
    var previous = TableCell()
    var result = [[TableCell]()]
    var sectionCounter = 0
    var rowCounter = 0
    
    for message in messages {
      var cell = TableCell(message)
      let messageContent = message.content
      let attributedContent = processMarkdown(messageContent)
      cell.attributedContent = attributedContent
      
      if previous.isEmpty {
        result[sectionCounter].append(cell)
        previous = cell
        continue
      }
      
      if previous.display_recipient != cell.display_recipient ||
        previous.subject != cell.subject ||
        previous.type != cell.type {
          
          sectionCounter++
          rowCounter = 0
          cell.section = sectionCounter
          cell.row = rowCounter
          result.append([cell])
      }
      else {
        if previous.sender_full_name == cell.sender_full_name {
          cell.cellType = CellTypes.ExtendedCell
        }
        
        rowCounter++
        cell.section = sectionCounter
        cell.row = rowCounter
        result[sectionCounter].append(cell)
      }
      previous = cell
    }
    
    return result
  }
  
  private func processMarkdown(text: String) -> NSAttributedString! {
    //Swift adds an extra "\n" to paragraph tags so we replace with span.
    var text = text.stringByReplacingOccurrencesOfString("<p>", withString: "<span>")
    text = text.stringByReplacingOccurrencesOfString("</p>", withString: "</span>")
    //Stolen from the original zulip-ios project
    let style = ["<style>",
      "body{font-family:\"SourceSansPro-Regular\";font-size:15px;line-height:15px;}",
      "span.user-mention {padding: 2px 4px; background-color: #F2F2F2; border: 1px solid #e1e1e8;}",
      ".hll{background-color:#ffc}{background:#f8f8f8} .c{color:#408080;font-style:italic} .err{border:1px solid #f00} .k{color:#008000;font-weight:bold} .o{color:#666} .cm{color:#408080;font-style:italic} .cp{color:#bc7a00} .c1{color:#408080;font-style:italic} .cs{color:#408080;font-style:italic} .gd{color:#a00000} .ge{font-style:italic} .gr{color:#f00} .gh{color:#000080;font-weight:bold} .gi{color:#00a000} .go{color:#808080} .gp{color:#000080;font-weight:bold} .gs{font-weight:bold} .gu{color:#800080;font-weight:bold} .gt{color:#0040d0} .kc{color:#008000;font-weight:bold} .kd{color:#008000;font-weight:bold} .kn{color:#008000;font-weight:bold} span.kp{color:#008000} .kr{color:#008000;font-weight:bold} .kt{color:#b00040} .m{color:#666} .s{color:#ba2121} .na{color:#7d9029} .nb{color:#008000} .nc{color:#00f;font-weight:bold} .no{color:#800} .nd{color:#a2f} .ni{color:#999;font-weight:bold} .ne{color:#d2413a;font-weight:bold} .nf{color:#00f} .nl{color:#a0a000} .nn{color:#00f;font-weight:bold} .nt{color:#008000;font-weight:bold} .nv{color:#19177c} .ow{color:#a2f;font-weight:bold} .w{color:#bbb} .mf{color:#666} .mh{color:#666} .mi{color:#666} .mo{color:#666} .sb{color:#ba2121} .sc{color:#ba2121} .sd{color:#ba2121;font-style:italic} .s2{color:#ba2121} .se{color:#b62;font-weight:bold} .sh{color:#ba2121} .si{color:#b68;font-weight:bold} .sx{color:#008000} .sr{color:#b68} .s1{color:#ba2121} .ss{color:#19177c} .bp{color:#008000} .vc{color:#19177c} .vg{color:#19177c} .vi{color:#19177c} .il{color:#666}",
      "blockquote {border-left-color: #dddddd;border-left-style: solid;border-left: 5px;}",
      "a {color:0088cc}",
      "code {padding: 2px 4px;color: #d14;background-color: #F5F5F5;border: 1px solid #e1e1e8;}",
      "img {max-height: 200px}",
      "</style>"].reduce("",combine: +)
    text += style
    let htmlString: NSAttributedString?
    let htmlData = text.dataUsingEncoding(NSUTF16StringEncoding, allowLossyConversion: false)
    
    do {
      htmlString = try NSAttributedString(data: htmlData!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
    } catch _ {
      htmlString = nil
    }
    return htmlString
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
  
  //writes subscription dictionary, realm persistence, other registration info
  private func recordRegistration(registration: Registration) {
    for sub in registration.subscription {
      subscription[sub["name"].stringValue] = sub["color"].stringValue
    }
    subscriptionsToRealm(registration.subscription)
    self.registration = registration
  }
  
  private func subscriptionsToRealm(subscriptions: [JSON]) {
    print("writing subscriptions")
    print("save path: \(realm.path)")
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