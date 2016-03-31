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
  private var streamPredicate: NSPredicate?
  private var subjectPredicate: NSPredicate?
  private var mentionedPredicate: NSPredicate?
  private var pmWithPredicate: NSPredicate?
  
  private(set) var type: Type = .Stream {
    didSet {
      self.typePredicate = NSPredicate(format: "type = %@", type.description)
    }
  }
  
  private(set) var stream = [String]() {
    didSet {
      let predicate = NSPredicate(format: "ALL %@ IN %K", stream, "display_recipient")
      let conversePredicate = NSPredicate(format: "ALL %K IN %@", "display_recipient", stream)
      self.streamPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, conversePredicate])
    }
  }
  
  private(set) var pmWith = [String]() {
    didSet {
      let predicate = NSPredicate(format: "ALL %@ in %K", pmWith, "pmWith")
      let conversePredicate = NSPredicate(format: "ALL %K in %@", "pmWith", pmWith)
      pmWithPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, conversePredicate])
    }
  }
  
  private(set) var subject: String? = nil {
    didSet {
      if subject != nil {
        self.subjectPredicate = NSPredicate(format: "subject =[cd] %@", subject!)
      }
    }
  }
  
  private(set) var mentioned = false {
    didSet {
      self.mentionedPredicate = NSPredicate(format: "mentioned = %@", mentioned)
    }
  }
  
  private(set) var narrowString: String?
  
  init() {}
  
  //inits are wrapped in closures to trigger didSet
  init(narrowString: String?, type: Type? = nil, mentioned: Bool? = nil) {
    {
      self.narrowString = narrowString
      if type == .Private {self.type = type!}
      if let mentioned = mentioned {self.mentioned = mentioned}
    }()
  }
  
  init(narrowString: String?, stream: String) {
    {
      self.narrowString = narrowString
      self.stream = [stream]
    }()
  }
  
  init(narrowString: String?, stream: String, subject: String) {
    {
      self.narrowString = narrowString
      self.stream = [stream]
      self.subject = subject
    }()
  }
  
  init(narrowString: String?, pmWith: [String]) {
    {
      self.narrowString = narrowString
      self.pmWith = pmWith
      self.type = .Private
    }()
  }
  
  func predicate() -> NSPredicate {
    let arr = [typePredicate, streamPredicate, subjectPredicate, mentionedPredicate, pmWithPredicate]
    let predicateArray = arr.filter {if $0 == nil {return false}; return true}.map {$0!}
    let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicateArray)
    print("action predicate: \(compoundPredicate)")
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

