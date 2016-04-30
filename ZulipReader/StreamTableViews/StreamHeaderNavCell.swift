//
//  StreamHeaderNavCell.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/2/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import Spring
import Kingfisher

protocol StreamHeaderNavCellDelegate: class {
      func narrowStream(stream: String)
      func narrowSubject(stream: String, subject: String)
}

class StreamHeaderNavCell: ZulipTableViewCell {
  
  weak var delegate: StreamHeaderNavCellDelegate?
  
  @IBOutlet weak var streamLabel: UIButton!
  @IBOutlet weak var subjectLabel: UIButton!
  
  @IBAction func streamButtonDidTouch(sender: AnyObject) {
    delegate?.narrowStream(streamLabel.titleForState(UIControlState.Normal)!)
  }
  
  @IBAction func subjectButtonDidTouch(sender: AnyObject) {
    delegate?.narrowSubject(streamLabel.titleForState(UIControlState.Normal)!, subject: subjectLabel.titleForState(UIControlState.Normal)!)
  }
  
  override func configure(message: TableCell) {
    streamLabel.setTitle(message.display_recipient.first, forState: UIControlState.Normal)
    subjectLabel.setTitle(message.subject, forState: UIControlState.Normal)
    
    let image = streamLabel.currentBackgroundImage?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
    streamLabel.setBackgroundImage(image, forState: UIControlState.Normal)
    streamLabel.tintColor = UIColor(hex: message.streamColor)
  }
}