//
//  SideMenuTitle.swift
//  ZulipReader
//
//  Created by Frank Tan on 4/22/16.
//  Copyright © 2016 Frank Tan. All rights reserved.
//

import UIKit
import Spring

class SideMenuTitle: UIView {
  
  @IBOutlet weak var titleLabel: UILabel!
  
  func configure(title: String) {
    titleLabel.text = title
  }
}
