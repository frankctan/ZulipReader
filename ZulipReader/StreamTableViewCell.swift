//
//  StreamTableViewCell.swift
//  ZulipReader
//
//  Created by Frank Tan on 11/23/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import Spring
import Kingfisher


class StreamTableViewCell: UITableViewCell {

    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var contentTextView: AutoTextView!
    
    func configureWithStream(message: Cell) {
        nameLabel.text = message.name
        badgeImageView.kf_setImageWithURL(NSURL(string: message.avatarURL)!, placeholderImage: nil)
        contentTextView.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        layoutIfNeeded()
        let attributedContent = htmlToAttributedString(message.content + "<style>span{font-family:\"SourceSansPro-Regular\";font-size:15px;line-height:15px;}</style>")
        timeLabel.text = message.timestamp
        contentTextView.text = nil
        contentTextView.attributedText = nil
        contentTextView.attributedText = attributedContent
    }
}