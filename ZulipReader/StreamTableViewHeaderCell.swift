//
//  StreamTableViewHeaderCell.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/2/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import Spring
import Kingfisher

class StreamTableViewHeaderCell: UITableViewCell {

    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    func configureWithStream(message: UserHeaderCell) {
        nameLabel.text = message.name
        badgeImageView.kf_setImageWithURL(NSURL(string: message.avatarURL)!, placeholderImage: nil)
    }
}
