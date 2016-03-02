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
    case .Stream: return "Stream"
    case .Private: return "Private"
    }
  }
}

public struct Narrow {
  private var typePredicate: NSPredicate?
  private var recipientPredicate: NSPredicate?
  private var subjectPredicate: NSPredicate?
  private var mentionedPredicate: NSPredicate?
  private var narrowFlagPredicate: NSPredicate?
  
  var type: Type = .Stream {
    didSet {
      self.typePredicate = NSPredicate(format: "type = %@", type.description)
      print("type Predicate: \(typePredicate)")
    }
  }
  
  var recipient = [String]() {
    didSet {
      self.recipientPredicate = NSPredicate(format: "ALL %@ IN %K", recipient, "display_recipient")
    }
  }
  
  var subject = "" {
    didSet {
      self.subjectPredicate = NSPredicate(format: "subject = %@", subject)
    }
  }
  
  var mentioned = false {
    didSet {
      self.mentionedPredicate = NSPredicate(format: "mentioned = %@", mentioned)
    }
  }
  
  var narrowFlag = false {
    didSet {
      self.narrowFlagPredicate = NSPredicate(format: "narrow = %@", narrowFlag)
    }
  }
  
  var narrowString: String?
  
  init() {
    {self.narrowFlag = false}()
  }
  
  //inits are wrapped in closures to trigger the didSets
  init(type: Type) {
    {self.narrowFlag = false
      if type == .Private {
        self.type = type
      }
    }()
  }
  
  init(narrowString: String?, stream: String) {
    {self.narrowString = narrowString
      self.recipient = [stream]}()
  }
  
  init(narrowString: String?, stream: String, subject: String) {
    {self.narrowString = narrowString
      self.recipient = [stream]
      self.subject = subject}()
  }
  
  init(narrowString: String?, privateRecipients: [String]) {
    {self.narrowString = narrowString
      self.recipient = privateRecipients
      self.type = .Private}()
  }
  
  func predicate() -> NSPredicate {
    let arr = [typePredicate, recipientPredicate, subjectPredicate, mentionedPredicate, narrowFlagPredicate]
    let predicateArray = arr.filter {if $0 == nil {return false}; return true}.map {$0!}
    let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicateArray)
    print("new predicate: \(compoundPredicate)")
    return compoundPredicate
  }
}

public struct Action {
  let narrow: Narrow
  var userAction:UserAction
  
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

