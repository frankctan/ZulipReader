//
//  StreamTableViewHeaderNavCell.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/2/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import Spring
import Kingfisher

protocol StreamTableViewHeaderNavCellDelegate: class {
    func narrowStream(stream: String)
    func narrowSubject(stream: String, subject: String)
}

class StreamTableViewHeaderNavCell: UITableViewCell {

    
    weak var delegate: StreamTableViewHeaderNavCellDelegate?
    @IBOutlet weak var streamLabel: UIButton!
    @IBOutlet weak var subjectLabel: UIButton!
    
    @IBAction func streamButtonDidTouch(sender: AnyObject) {
        delegate?.narrowStream(streamLabel.titleForState(UIControlState.Normal)!)
    }
    
    @IBAction func subjectButtonDidTouch(sender: AnyObject) {
        delegate?.narrowSubject(streamLabel.titleForState(UIControlState.Normal)!, subject: subjectLabel.titleForState(UIControlState.Normal)!)
    }
    
    func configureWithStream(message: Cell) {
        streamLabel.setTitle(message.stream, forState: UIControlState.Normal)
        subjectLabel.setTitle(message.subject, forState: UIControlState.Normal)
        
        let image = streamLabel.currentBackgroundImage?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        streamLabel.setBackgroundImage(image, forState: UIControlState.Normal)
        streamLabel.tintColor = UIColor(hex: message.streamColor)
    }
}