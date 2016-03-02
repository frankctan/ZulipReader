//
//  StreamHeaderPrivateCell.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/2/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import Spring
import Kingfisher

protocol StreamHeaderPrivateCellDelegate: class {
  func narrowConversation(emails: [String])
}

class StreamHeaderPrivateCell: ZulipTableViewCell {
  
  weak var delegate: StreamHeaderPrivateCellDelegate?
  @IBOutlet weak var privateLabel: UIButton!
  var recipientEmails = [String]()
  
  @IBAction func privateButtonDidTouch(sender: AnyObject) {
    delegate?.narrowConversation(recipientEmails)
  }
  
  override func configure(message: TableCell) {
    recipientEmails = Array(message.display_recipient.sort())
    let recipientNames = Array(message.privateFullName.sort())
    let title: String
    let recipientCount = recipientNames.count
    
    switch recipientCount {
    case 0: title = "You"
    case 1: title = "You & \(recipientNames[0])"
    default: title = "You & \(recipientCount) others"
    }
    privateLabel.setTitle(title, forState: UIControlState.Normal)
  }
}