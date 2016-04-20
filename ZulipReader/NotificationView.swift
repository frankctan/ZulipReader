//
//  NotificationView.swift
//  ZulipReader
//
//  Created by Frank Tan on 4/14/16.
//  Copyright © 2016 Frank Tan. All rights reserved.
//

import UIKit

protocol NotificationViewDelegate: class {
  func dismissButtonDidTouch()
  func scrollDownButtonDidTouch()
}

class NotificationView: UIView {

  @IBOutlet weak var dismissButton: UIButton!
  @IBOutlet weak var scrollDownButton: UIButton!
  @IBOutlet weak var notificationLabel: UILabel!
  
  weak var delegate: NotificationViewDelegate?
  
  func configure(notification: Notification) {
    let labelText: String
    switch notification {
    case .NewMessage(let count):
      if count > 1 {
        labelText = "\(count) new messages"
      } else {
        labelText = "new message"
      }
      scrollDownButton.hidden = false
      self.backgroundColor = UIColor.greenColor()
      
    case .Error(let errorMessage):
      labelText = errorMessage
      scrollDownButton.hidden = true
      self.backgroundColor = UIColor.redColor()
      
    default:
      labelText = "this shouldn't be here"
    }
    
    print("NotificationView: \(labelText)")
    self.changeLabelTextTo(labelText)
  }
  
  func changeLabelTextTo(string: String?) {
    notificationLabel.text = string
  }
  
  @IBAction func dismissButtonDidTouch(sender: AnyObject) {
    self.delegate?.dismissButtonDidTouch()
  }
  
  @IBAction func scrollDownButtonDidTouch(sender: AnyObject) {
    self.delegate?.scrollDownButtonDidTouch()
  }
}
