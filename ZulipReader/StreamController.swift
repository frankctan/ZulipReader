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
  func didFetchMesssages(messages: [[TableCell]], newMessages indexPaths: (inserted: [NSIndexPath], deleted: [NSIndexPath]), action: UserAction)
}

public enum UserAction {
  case ScrollUp, ScrollDown, Refresh, Register, Home
  case Narrow(narrow: String)
}

class StreamController : DataController {
  
  weak var delegate: StreamControllerDelegate?
  
  private let realm: Realm
  private var subscription: [String:String] = [:]
  private var registration = Registration()
  private var oldTableCells = [[TableCell]]()
  
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
  
  private struct MessageRequestParameters {
    let numBefore: Int
    let numAfter: Int
    let numAnchor: Int
    let narrows: String?
    
    init() {
      self = MessageRequestParameters(anchor: 0)
    }
    
    init(anchor: Int) {
      numAnchor = anchor
      numBefore = 50
      numAfter = 50
      narrows = nil
    }
    
    init(anchor: Int, before: Int, after: Int) {
      numAnchor = anchor
      numBefore = before
      numAfter = after
      narrows = nil
    }
    
    init(anchor: Int, before: Int, after: Int, narrow: String) {
      numAnchor = anchor
      numBefore = before
      numAfter = after
      narrows = narrow
    }
  }
  
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
    //    realm.deleteAll()
    do {
      try Locksmith.deleteDataForUserAccount("default")
    }
    catch {fatalError("unable to clear Locksmith")}
  }
  
  //MARK: Get Stream Messages
  var loading = false
  
  func loadStreamMessages(action: UserAction) {
    if loading {
      return
    }
    loading = true
    
    var userAction = action
    
    switch action {
    case .Refresh, .Home:
      let messagesToBeLoaded = self.realm.objects(Message).sorted("timestamp", ascending: true).map {$0}
      tableCellsToController(action, messages: messagesToBeLoaded)
      userAction = .Refresh
    default: break
    }
    
    let params = createRequestParameters(userAction)
    messagePipeline(params)
      .start {result in
        switch result {
        case .Success(let boxedMessages):
          var newMessages = boxedMessages.unbox
          if params.narrows == nil {
            //self.messagesToRealm does not write duplicates
            self.messagesToRealm(newMessages)
            newMessages = self.realm.objects(Message).sorted("timestamp", ascending: true).map {$0}
          }
          
          self.tableCellsToController(userAction, messages: newMessages)
          
        case .Error(let error):
          print(error.unbox.description)
        }
        self.loading = false
    }
  }
  
  private func tableCellsToController(action: UserAction, messages: [Message]) {
    let tableCells = self.convertToCell(messages)

    if (self.oldTableCells.flatMap{$0}.map{$0.dateTime}) != (tableCells.flatMap{$0}.map {$0.dateTime}) {
      print("old table cells do not match new table cells")
      let (inserted, deleted) = self.findNewMessages(tableCells, action: action)
      self.delegate?.didFetchMesssages(tableCells, newMessages: (inserted: inserted, deleted: deleted), action: action)
      self.oldTableCells = tableCells
    }
    return
  }
  
  private func findNewMessages(tableCells: [[TableCell]], action: UserAction) -> (inserted: [NSIndexPath], deleted: [NSIndexPath]) {
    var insert = [NSIndexPath]()
    var delete = [NSIndexPath]()
    
    let flatTableCells = tableCells.flatMap {$0}
    let flatOldTableCells = oldTableCells.flatMap {$0}
    
    switch action {
    case .Narrow(_), .Home:
      for tableCell in flatOldTableCells {
        delete.append(NSIndexPath(forRow: tableCell.row, inSection: tableCell.section))
      }
      for tableCell in flatTableCells {
        insert.append(NSIndexPath(forRow: tableCell.row, inSection: tableCell.section))
      }
    default:
      let oldTableCellTimeStamp = flatOldTableCells.map {$0.dateTime}
      for tableCell in flatTableCells {
        if !oldTableCellTimeStamp.contains(tableCell.dateTime) {
          insert.append(NSIndexPath(forRow: tableCell.row, inSection: tableCell.section))
        }
      }
    }
    return (insert, delete)
  }
  
  private func messagePipeline(params: MessageRequestParameters) -> Future<[Message], ZulipErrorDomain> {
    return createMessageRequest(params)
      .andThen(AlamofireRequest)
      .andThen(processResponse)
  }
  
  private func createRequestParameters(action: UserAction) -> MessageRequestParameters {
    var params = MessageRequestParameters()
    let (minAnchor, maxAnchor) = getAnchor()
    
    switch action {
    case .ScrollDown, .Refresh, .Home:
      params = MessageRequestParameters(anchor: maxAnchor, before: 0, after: 5)
    case .ScrollUp:
      params = MessageRequestParameters(anchor: minAnchor, before: 50, after: 0)
    case .Narrow(let narrow):
      params = MessageRequestParameters(anchor: maxAnchor, before: 50, after: 50, narrow: narrow)
    case .Register:
      params = MessageRequestParameters(anchor: maxAnchor, before: 50, after: 50)
    }
    return params
  }
  
  private func getAnchor() -> (min: Int, max: Int) {
    let messages = realm.objects(Message).sorted("timestamp", ascending: false)
    
    var realmMaxID = 0
    if let first = messages.first {
      realmMaxID = first.id
    }
    
    let registrationID = registration.maxMessageID
    var realmMinID = 0
    if let last = messages.last {
      realmMinID = last.id
    }
    //offset by 1 to reduce duplicates
    return (realmMinID-1, max(realmMaxID, registrationID)+1)
  }
  
  private func createMessageRequest(params: MessageRequestParameters) -> Future<URLRequestConvertible, ZulipErrorDomain> {
    let urlRequest: URLRequestConvertible
    if let narrowRequest = params.narrows {
      urlRequest = Router.GetNarrowMessages(anchor: params.numAnchor, before: params.numBefore, after: params.numAfter, narrow: narrowRequest)
    }
    else {
      urlRequest = Router.GetOldMessages(anchor: params.numAnchor, before: params.numBefore, after: params.numAfter)
    }
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
  
  //checks for uniqueness based on dateTime
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
  private func convertToCell(messages: [Message]) -> [[TableCell]] {
    var previous = TableCell()
    var result = [[TableCell]()]
    var sectionCounter = 0
    var rowCounter = 0
    for message in messages {
      var cell = TableCell(message)
      cell.attributedContent = processMarkdown(message.content)
      
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
    print(result.count)
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
    let htmlData = text.dataUsingEncoding(NSUTF16StringEncoding, allowLossyConversion: false)
    let htmlString: NSAttributedString?
    do {
      htmlString = try NSAttributedString(data: htmlData!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
    } catch _ {
      htmlString = nil
    }
    return htmlString
  }
  
  //MARK: Register
  func register() {
    registrationPipeline()
      .start { result in
        switch result {
          
        case .Success(let boxedReg):
          let reg = boxedReg.unbox
          self.recordRegistration(reg)
          self.loadStreamMessages(.Register)
          
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