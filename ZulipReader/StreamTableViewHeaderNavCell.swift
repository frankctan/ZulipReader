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

class StreamTableViewHeaderNavCell: UITableViewCell {

    @IBOutlet weak var streamLabel: UIButton!
    @IBOutlet weak var subjectLabel: UIButton!
    
    func configureWithStream(message: Cell) {
        streamLabel.setTitle(message.stream, forState: UIControlState.Normal)
        subjectLabel.setTitle(message.subject, forState: UIControlState.Normal)
        
        let image = streamLabel.currentBackgroundImage?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        streamLabel.setBackgroundImage(image, forState: UIControlState.Normal)
        streamLabel.tintColor = UIColor(hex: message.streamColor)
    }
}