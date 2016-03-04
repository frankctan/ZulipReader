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


class StreamCell: ZulipTableViewCell {
  
  @IBOutlet weak var badgeImageView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var contentTextView: AutoTextView!
  
  override func configure(message: TableCell) {
    nameLabel.text = message.sender_full_name
    badgeImageView.kf_setImageWithURL(NSURL(string: message.avatar_url)!, placeholderImage: nil)
    contentTextView.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
    layoutIfNeeded()

    timeLabel.text = timeAgoSinceDate(message.dateTime, numericDates: true)
    
    contentTextView.attributedText = message.attributedContent
    self.backgroundColor = UIColor(hex: "FFFFFF")
    
    if message.type == .Private {
      self.backgroundColor = UIColor(hex: "FEFFE0")
    }
    if message.mentioned == true {
      self.backgroundColor = UIColor(hex: "FFE4E0")
    }
  }
}