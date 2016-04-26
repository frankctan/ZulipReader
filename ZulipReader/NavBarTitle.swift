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
  var scrollButtonHidden: Bool = false
  var title: String = ""
  
  func configure(scrollDown: Bool, title: String) {
    self.scrollButtonHidden = scrollDown
    self.title = title
    
    if scrollDown {
      titleButton.setImage(UIImage(named: "Circled Down-96-2"), forState: .Normal)
    } else {
      titleButton.setImage(nil, forState: .Normal)
    }
    
    titleButton.setTitle(title, forState: .Normal)
  }
}
