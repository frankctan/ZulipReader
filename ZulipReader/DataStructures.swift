//
//  DataStructures.swift
//  ZulipReader
//
//  Created by Frank Tan on 3/2/16.
//  Copyright © 2016 Frank Tan. All rights reserved.
//

import Foundation

public enum UserAction {
  case ScrollUp, Refresh, Focus
}

public enum Type {
  case Stream, Private
  
  var description: String {
    switch self {
    case .Stream: return "stream"
    case .Private: return "private"
    }
  }
}

public struct MessagePost {
  let content: String
  let recipient: [String]
  let subject: String?
  let type: Type
  
  init(content: String, recipient: [String], subject: String?) {
    self.content = content
    self.recipient = recipient
    if let subject = subject {
      self.subject = subject
      self.type = .Stream
    }
    else {
      self.subject = nil
      self.type = .Private
    }
  }
}

public struct Narrow {
  private var typePredicate: NSPredicate?
  private var recipientPredicate: NSPredicate?
  private var subjectPredicate: NSPredicate?
  private var mentionedPredicate: NSPredicate?
  private var minimumIDPredicate: NSPredicate?
  private var maximumIDPredicate: NSPredicate?
  
  var type: Type = .Stream {
    didSet {
      self.typePredicate = NSPredicate(format: "type = %@", type.description)
      print("type Predicate: \(typePredicate)")
    }
  }
  
  var recipient = [String]() {
    didSet {
      let predicate = NSPredicate(format: "ALL %@ IN %K", recipient, "display_recipient")
      let conversePredicate = NSPredicate(format: "ALL %K IN %@", "display_recipient", recipient)
      self.recipientPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, conversePredicate])
    }
  }
  
  var subject:String? = nil {
    didSet {
      if subject != nil {
        self.subjectPredicate = NSPredicate(format: "subject =[cd] %@", subject!)
      }
    }
  }
  
  var mentioned = false {
    didSet {
      self.mentionedPredicate = NSPredicate(format: "mentioned = %@", mentioned)
    }
  }
  
  var minimumMessageID = Int.max {
    didSet {
      self.minimumIDPredicate = NSPredicate(format: "id >= %d", minimumMessageID)
    }
  }
  
  var maximumMessageID = Int.min {
    didSet {
      self.maximumIDPredicate = NSPredicate(format: "id<= %d", maximumMessageID)
    }
  }
  
  var narrowString: String?
  
  init() {
  }
  
  //inits are wrapped in closures to trigger didSet
  init(type: Type) {
    {
      if type == .Private {self.type = type}
    }()
  }
  
  init(narrowString: String?, type: Type?, mentioned: Bool?) {
    {
      self.narrowString = narrowString
      if type == .Private {self.type = type!}
      if let mentioned = mentioned {self.mentioned = mentioned}
    }()
  }
  
  init(narrowString: String?, stream: String) {
    {
      self.narrowString = narrowString
      self.recipient = [stream]
    }()
  }
  
  init(narrowString: String?, stream: String, subject: String) {
    {
      self.narrowString = narrowString
      self.recipient = [stream]
      self.subject = subject
    }()
  }
  
  init(narrowString: String?, privateRecipients: [String]) {
    {
      self.narrowString = narrowString
      self.recipient = privateRecipients
      self.type = .Private
    }()
  }
  
  func predicate() -> NSPredicate {
    let arr = [typePredicate, recipientPredicate, subjectPredicate, mentionedPredicate, minimumIDPredicate, maximumIDPredicate]
    let predicateArray = arr.filter {if $0 == nil {return false}; return true}.map {$0!}
    let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicateArray)
    print("new predicate: \(compoundPredicate)")
    return compoundPredicate
  }
}

public struct Action {
  var narrow: Narrow
  var userAction: UserAction
  
  init() {
    self.narrow = Narrow()
    self.userAction = .Focus
  }
  
  init(narrow: Narrow) {
    self.narrow = narrow
    userAction = .Refresh
  }
  
  init(action: UserAction) {
    self.narrow = Narrow()
    userAction = action
  }
  
  init(narrow: Narrow, action: UserAction) {
    self.narrow = narrow
    userAction = action
  }
}

public struct MessageRequestParameters {
  let numBefore: Int
  let numAfter: Int
  let numAnchor: Int
  let narrow: String?
  
  init() {
    self = MessageRequestParameters(anchor: 0)
  }
  
  init(anchor: Int) {
    numAnchor = anchor
    numBefore = 50
    numAfter = 50
    narrow = nil
  }
  
  init(anchor: Int, before: Int, after: Int) {
    numAnchor = anchor
    numBefore = before
    numAfter = after
    narrow = nil
  }
  
  init(anchor: Int, before: Int, after: Int, narrow: String?) {
    numAnchor = anchor
    numBefore = before
    numAfter = after
    if let narrowParams = narrow {
      self.narrow = narrowParams
    }
    else {
      self.narrow = nil
    }
  }
}

