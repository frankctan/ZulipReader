//
//  TableCell.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/3/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import Spring
import Kingfisher

enum CellTypes {
  case StreamCell, ExtendedCell
  
  var string: String {
    switch self {
    case .StreamCell: return "StreamCell"
    case . ExtendedCell : return "StreamExtendedCell"
    }
  }
}

struct TableCell {
  var display_recipient = Set<String>()
  var privateFullName = Set<String>()
  var subject = ""
  var type:Type = .Stream
  var streamColor = ""
  
  var sender_full_name = ""

  var dateTime = NSDate()
  var avatar_url = ""
  var mentioned = false
  
  var cellType = CellTypes.StreamCell
  var attributedContent = NSAttributedString()
  
  var section = 0
  var row = 0
  
  var id = 0
  
  
  //used for initialization of [[TableCell]]
  var isEmpty = true
  
  init() {}
  
  init(_ message: Message) {
    display_recipient = Set(message.display_recipient)
    privateFullName = Set(message.privateFullName)
    subject = message.subject
    if message.type == "private" {self.type = .Private}
    streamColor = message.streamColor
    
    sender_full_name = message.sender_full_name
    dateTime = message.dateTime
    avatar_url = message.avatar_url
    mentioned = message.mentioned
    
    id = message.id
    
    isEmpty = false
    
  }
}