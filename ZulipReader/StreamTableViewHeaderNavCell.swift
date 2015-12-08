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

    @IBOutlet weak var streamLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    
    func configureWithStream(message: StreamHeaderCell) {
        
        streamLabel.text = message.stream
        subjectLabel.text = message.subject
    }

}
