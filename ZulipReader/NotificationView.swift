//
//  NotificationView.swift
//  ZulipReader
//
//  Created by Frank Tan on 4/14/16.
//  Copyright © 2016 Frank Tan. All rights reserved.
//

import UIKit

protocol NotificationViewDelegate: class {
  func dismissDidTouch()
  func scrollDownDidTouch()
}

class NotificationView: UIView {

  @IBOutlet weak var dismissButton: UIButton!
  @IBOutlet weak var scrollDownButton: UIButton!
  @IBOutlet weak var notificationLabel: UILabel!
  
  weak var delegate: NotificationViewDelegate?
  
  func changeLabelTextTo(string: String) {
    notificationLabel.text = string
  }
  
  @IBAction func dismissButtonDidTouch(sender: AnyObject) {
    self.delegate?.dismissDidTouch()
  }
  
  @IBAction func scrollDownButtonDidTouch(sender: AnyObject) {
    self.delegate?.scrollDownDidTouch()
  }
}
