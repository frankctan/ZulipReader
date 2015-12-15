//
//  StreamCell.Swift
//  ZulipReader
//
//  Created by Frank Tan on 11/23/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import Spring
import Kingfisher


class StreamCell: UITableViewCell {

    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var contentTextView: AutoTextView!
    
    func configureWithStream(message: Cell) {
        nameLabel.text = message.name
        badgeImageView.kf_setImageWithURL(NSURL(string: message.avatarURL)!, placeholderImage: nil)
        contentTextView.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        layoutIfNeeded()
        let attributedContent = message.content
        timeLabel.text = message.timestamp
        contentTextView.text = nil
        contentTextView.attributedText = nil
        contentTextView.attributedText = attributedContent

        switch message.type {
        case "private": self.backgroundColor = UIColor(hex: "FEFFE0")
        case "mentioned": self.backgroundColor = UIColor(hex: "FFE4E0")
        default: self.backgroundColor = UIColor(hex: "FFFFFF")
        }
    }
}