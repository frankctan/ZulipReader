//
//  NavBarTitle.swift
//  ZulipReader
//
//  Created by Frank Tan on 4/22/16.
//  Copyright © 2016 Frank Tan. All rights reserved.
//

import UIKit
import Spring

class NavBarTitle: UIView {

  @IBOutlet weak var titleButton: SpringButton!
  
  func configure(scrollDown: Bool, title: String) {
    if scrollDown {
      titleButton.setImage(UIImage(named: "Circled Down-96-2"), forState: .Normal)
    } else {
      titleButton.setImage(nil, forState: .Normal)
    }
    
    titleButton.setTitle(title, forState: .Normal)
  }
  
  @IBAction func titleButtonDidPress(sender: AnyObject) {
    print("hehe!")
  }
}
