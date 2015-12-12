//
//  StreamTableViewExtendedCell.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/11/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import Spring
import Kingfisher

class StreamTableViewExtendedCell: UITableViewCell {
    
    @IBOutlet weak var contentTextView: AutoTextView!
    
    func configureWithStream(message: Cell) {
        contentTextView.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        layoutIfNeeded()
        let attributedContent = htmlToAttributedString(message.content + "<style>span{font-family:\"SourceSansPro-Regular\";font-size:15px;line-height:15px;}</style>")
        contentTextView.text = nil
        contentTextView.attributedText = nil
        contentTextView.attributedText = attributedContent
    }
}