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

class StreamHeaderPrivateCell: UITableViewCell {
    
    weak var delegate: StreamHeaderPrivateCellDelegate?
    @IBOutlet weak var privateLabel: UIButton!
    var recipientID:String!
    var title:String!
    var recipients:[String]!
    var recipientEmails = ""
    var type = ""
    var subject = ""

    @IBAction func privateButtonDidTouch(sender: AnyObject) {
        delegate?.narrowConversation(recipientID, cellTitle: title, emails: recipientEmails, msgType: type, msgSubject: subject, msgEmails: recipients)
    }
    
    func configureWithStream(message: Cell) {
        
        recipientID = message.recipientID
        recipients = message.recipients
        type = message.type
        subject = message.subject
        recipients = message.recipientEmail
        
        let recipientCount = message.recipients.count
        
        for emailCount in 0..<message.recipientEmail.count {
            if emailCount == 0 {
                recipientEmails = message.recipientEmail[emailCount]
            } else {
            recipientEmails += ",\(message.recipientEmail[emailCount])"
            }
        }
        
        if recipientCount > 1 {
            title = "You & \(recipientCount) others"
        } else {
            title = "You & \(message.recipients[0])"
        }
        privateLabel.setTitle(title, forState: UIControlState.Normal)
    }
}