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
  var display_recipient = [String]()
  var subject = ""
  var type = ""
  var streamColor = ""
  
  var sender_full_name = ""
  var content = ""
  var dateTime = NSDate()
  var avatar_url = ""
  var mentioned = false
  
  var cellType = CellTypes.StreamCell
  var attributedContent = NSAttributedString()
  
  //used for initialization of [[TableCell]]
  var isEmpty = true
  
  init() {}
  
  init(_ message: Message) {
    display_recipient = message.display_recipient
    subject = message.subject
    type = message.type
    streamColor = message.streamColor
    
    sender_full_name = message.sender_full_name
    content = message.content
    dateTime = message.dateTime
    avatar_url = message.avatar_url
    mentioned = message.mentioned
    
    isEmpty = false
    
  }
}