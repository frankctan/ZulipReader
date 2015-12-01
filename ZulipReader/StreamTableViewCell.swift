//
//  StreamTableViewCell.swift
//  ZulipReader
//
//  Created by Frank Tan on 11/23/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import SwiftyJSON

class StreamTableViewCell: UITableViewCell {

    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var contentTextView: UITextView!
    
    func configureWithStream(message: JSON) {
        nameLabel.text = message["sender_full_name"].stringValue
    }
    
    
}

/*We want:
timestamp
display_recipient
sender_full_name
content
avatar_url
flags
subject
*/


//{
//    "msg": "",
//    "messages": [
//    {
//    "recipient_id": 20330,
//    "sender_email": "bac1087@gmail.com",
//    "timestamp": 1448931264,
//    "display_recipient": "455 Broadway",
//    "sender_id": 8854,
//    "sender_full_name": "Benjamin Adam Cohen (W1'15)",
//    "sender_domain": "students.hackerschool.com",
//    "content": "<p>Whatever is decided about 'making presentations better', it would be useful if it could be boiled down to a kind of 5 point list for easy reference. Kind of like the social rules, it will help if its concise</p>",
//    "gravatar_hash": "c44cfbb3d7938bd98a97ab3119bfe35b",
//    "avatar_url": "https://secure.gravatar.com/avatar/c44cfbb3d7938bd98a97ab3119bfe35b?d=identicon",
//    "flags": [
//    "read"
//    ],
//    "client": "desktop app Mac 0.5.1",
//    "content_type": "text/html",
//    "subject_links": [],
//    "sender_short_name": "bac1087",
//    "type": "stream",
//    "id": 50285316,
//    "subject": "making presentations better"
//    },