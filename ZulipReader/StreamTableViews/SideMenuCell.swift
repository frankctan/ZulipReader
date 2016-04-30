//
//  SideMenuCell.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/15/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit

class SideMenuCell: UITableViewCell {

    @IBOutlet weak var streamLabel: UILabel!
    @IBOutlet weak var streamColor: UIView!
    
    func configureWithStream(stream: String, color: String) {
        streamLabel.text = stream
        streamColor.backgroundColor = UIColor(hex: color)
    }
}
