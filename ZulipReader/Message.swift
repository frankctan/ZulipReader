//
//  Message.swift
//  ZulipReader
//
//  Created by Frank Tan on 2/11/16.
//  Copyright © 2016 Frank Tan. All rights reserved.
//


import RealmSwift

class RealmString: Object {
  dynamic var stringValue = ""
}

class Message: Object {
  dynamic var content = ""
  dynamic var sender_short_name = ""
  
  var flags: [String] { //read, mentioned, more?
    get {
      return _backingFlags.map {$0.stringValue}
    }
    set {
      _backingFlags.removeAll()
      _backingFlags.appendContentsOf(newValue.map({ RealmString(value: [$0]) }))
    }
  }
  let _backingFlags = List<RealmString>()
  
  var display_recipient: [String] { //Collect the emails from this field.
    get {
      return _backingDisplayRecipient.map {$0.stringValue}
    }
    set {
      _backingDisplayRecipient.removeAll()
      _backingDisplayRecipient.appendContentsOf(newValue.map({ RealmString(value: [$0]) }))
    }
  }
  let _backingDisplayRecipient = List<RealmString>()

  dynamic var sender_id: Int = 0
  dynamic var avatar_url = ""
  
  dynamic var sender_email = ""
  dynamic var gravatar_hash = ""
  dynamic var client = ""
  dynamic var subject = ""
  dynamic var sender_full_name = ""
  dynamic var sender_domain = ""
  dynamic var timestamp: Int = 0
  dynamic var id: Int = 0
  dynamic var recipient_id: Int = 0
  dynamic var type = ""
  dynamic var content_type = ""
  
  //MARK: Unused Properties
  //  dynamic var subject_links = ""

  
  override static func ignoredProperties() -> [String] {
    return ["flags", "display_recipient"]
  }
}
