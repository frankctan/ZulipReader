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

class StreamExtendedCell: UITableViewCell {
    
    @IBOutlet weak var contentTextView: AutoTextView!
    
    func configureWithStream(message: Cell) {
        contentTextView.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        layoutIfNeeded()
        let attributedContent = message.content
        contentTextView.text = nil
        contentTextView.attributedText = nil
        contentTextView.attributedText = attributedContent
        
        self.backgroundColor = UIColor(hex: "FFFFFF")
        
        if message.type == "private" {
            self.backgroundColor = UIColor(hex: "FEFFE0")
        }
        if message.mention == true {
            self.backgroundColor = UIColor(hex: "FFE4E0")
        }
    }
}