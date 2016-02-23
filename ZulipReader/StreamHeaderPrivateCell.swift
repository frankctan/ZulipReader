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
    func narrowConversation(recipientID: String, cellTitle: String, emails: String, msgType: String, msgSubject: String, msgEmails: [String])
}

class StreamHeaderPrivateCell: ZulipTableViewCell {
    
    weak var delegate: StreamHeaderPrivateCellDelegate?
    @IBOutlet weak var privateLabel: UIButton!
    var title:String!
    var recipients:[String]!
    var recipientEmails = Set<String>()
    var recipientEmailString = ""
    var type = ""
    var subject = ""

//    @IBAction func privateButtonDidTouch(sender: AnyObject) {
//        delegate?.narrowConversation(recipientID, cellTitle: title, emails: recipientEmailString, msgType: type, msgSubject: subject, msgEmails: recipients)
//    }
  
    override func configure(message: TableCell) {
//      
//        recipientEmails = message.display_recipient
//        recipients = message.recipientNames
//        type = message.type
//        subject = message.subject
////        recipients = message.recipientEmail
//        
//        let recipientCount = message.setRecipientEmail.count
//        
//        guard message.setRecipientEmail.count > 0 else {return}
//        
//        for email in message.setRecipientEmail {
//            recipientEmailString += "\(email),"
//        }
//        
//        if recipientEmailString.length > 2 {
//            recipientEmailString.removeAtIndex(recipientEmailString.endIndex.predecessor())
//        }
//    
//        if recipientCount > 1 {
//            title = "You & \(recipientCount) others"
//        } else {
//            title = "You & \(recipients[0])"
//        }
//        privateLabel.setTitle(title, forState: UIControlState.Normal)
    }
}