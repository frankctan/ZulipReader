//
//  NotificationNavViewController.swift
//  ZulipReader
//
//  Created by Frank Tan on 4/16/16.
//  Copyright © 2016 Frank Tan. All rights reserved.
//

import Foundation
import SlackTextViewController
import AMScrollingNavbar

enum Notification {
  case Error(errorMessage: String)
  case Badge
  case NewMessage(messageCount: Int)
}

class NotificationNavViewController: SLKTextViewController {
  
  var notification = NotificationView()
  var notificationDisplayed = false
  var navBarBadgeDisplayed = false
  var sideMenuTableViewController: SideMenuTableViewController?
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    //notifications
    let screenBounds = UIScreen.mainScreen().bounds
    self.notification = NSBundle.mainBundle().loadNibNamed("NotificationView", owner: nil, options: nil)[0] as! NotificationView
    self.notification.delegate = self
    self.notification.frame.size.width = screenBounds.width
    self.notification.frame.origin = CGPoint(x: 0, y: -notification.frame.height - 20)
    
    self.tableView.addSubview(self.notification)
    self.notification.hidden = true
    
    //configure view
    self.navigationControllerSettings()
    self.tableViewSettings()
    self.textViewControllerSettings()
  }
  
  func showNavBarBadge(flag: Bool) {
    guard self.navBarBadgeDisplayed != flag else {
      print("NotificationViewController: navBarBadge no change")
      return
    }
    
    self.navBarBadgeDisplayed = flag
    let image: UIImage?
    if self.navBarBadgeDisplayed {
      image = UIImage(named: "house283-notification")?.imageWithRenderingMode(.AlwaysOriginal)
      print("NotificationViewController: navBarBadge with badge")
    }
    else {
      image = UIImage(named: "house283-1")
      print("NotificationViewController: navBarBadge normal")
    }
    navigationItem.rightBarButtonItem?.image = image
  }
  
  func toggleNotification() {
    let originY: CGFloat
    let tableViewInset: CGFloat
    let notificationHeight = self.notification.frame.height
    
    if self.notificationDisplayed {
      //retract notification
      self.notificationDisplayed = false
      originY = -notificationHeight - 20
      tableViewInset = 0
    }
    else {
      //display notification
      self.notification.hidden = false
      self.tableView.bringSubviewToFront(self.notification)
      self.tableView.setNeedsDisplay()
      self.tableView.setNeedsLayout()
      
      self.notificationDisplayed = true
      originY = 0
      tableViewInset = notificationHeight
    }
    
    print("NotificationViewController: animating")
    
    UIView.animateWithDuration(0.2, delay: 0.0, options: [.AllowUserInteraction, .CurveEaseIn], animations: {
      self.tableView.bringSubviewToFront(self.notification)
      self.tableView.setNeedsDisplay()
      self.tableView.setNeedsLayout()
      self.notification.frame.origin.y = originY
      self.tableView.contentInset.top = tableViewInset
      }, completion: {_ in
//        self.notification.hidden = !self.notificationDisplayed
        self.tableView.setNeedsDisplay()
        self.tableView.setNeedsLayout()
    })
  }
  
  func showNotification(flag: Bool) {
    if self.notificationDisplayed != flag {
      self.toggleNotification()
    }
  }
  
  func scrollToBottom() {
    tableView.setNeedsLayout()
    let scrollToHeight = tableView.contentSize.height - tableView.frame.height
    let scrollToRect = CGRect(x: 0.0, y: scrollToHeight, width: tableView.frame.width, height: tableView.frame.height)
    tableView.scrollRectToVisible(scrollToRect, animated: true)
  }
  
  //MARK: Settings
  func navigationControllerSettings() {
    self.navigationController?.navigationBar.topItem?.title = "Stream"
    
    //navBar right bar button items
    self.navigationController?.navigationBar.translucent = false
    let homeBarButton = UIBarButtonItem(image: UIImage(named: "house283-1"), style: .Plain, target: self, action: #selector(StreamTableViewController.homeButtonDidTouch(_:)))
    navigationItem.setRightBarButtonItem(homeBarButton, animated: true)
    
    //navBar left bar button item - SideMenuNavigation
    let leftMenuBarButtonItem = UIBarButtonItem(image: UIImage(named: "menu"), style: .Plain, target: self.revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)))
    let sideMenuNavController = UINavigationController(rootViewController: self.sideMenuTableViewController!)
    self.revealViewController().rearViewController = sideMenuNavController
    self.navigationItem.setLeftBarButtonItem(leftMenuBarButtonItem, animated: true)
    
    //gesture Recognizer - SideMenuNavigation
    self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
  }
  
  func tableViewSettings() {
    
    tableView.scrollsToTop = true
    tableView.separatorStyle = UITableViewCellSeparatorStyle.None
    
    tableView.registerNib(UINib(nibName: "StreamHeaderNavCell", bundle: nil), forCellReuseIdentifier: "StreamHeaderNavCell")
    tableView.registerNib(UINib(nibName: "StreamHeaderPrivateCell", bundle: nil), forCellReuseIdentifier: "StreamHeaderPrivateCell")
    tableView.registerNib(UINib(nibName: "StreamCell", bundle: nil), forCellReuseIdentifier: "StreamCell")
    tableView.registerNib(UINib(nibName: "StreamExtendedCell", bundle: nil), forCellReuseIdentifier: "StreamExtendedCell")
  }
  
  func textViewControllerSettings() {
    self.setTextInputbarHidden(true, animated: false)
    self.bounces = true
    self.shakeToClearEnabled = true
    self.keyboardPanningEnabled = true
    self.inverted = false
    self.textView.placeholder = "Compose your message here!"
    self.textView.placeholderColor = UIColor.lightGrayColor()
    self.textInputbar.autoHideRightButton = true
    self.typingIndicatorView.canResignByTouch = true
    self.rightButton.setTitle("Send", forState: UIControlState.Normal)
  }
}

//MARK: NotificationViewDelegate
extension NotificationNavViewController: NotificationViewDelegate {
  func dismissButtonDidTouch() {
    self.toggleNotification()
  }
  func scrollDownButtonDidTouch() {
    self.scrollToBottom()
    self.toggleNotification()
  }
}

//MARK: ScrollViewControllerDelegate
extension NotificationNavViewController {
  override func scrollViewDidScroll(scrollView: UIScrollView) {
    //keep notification bar in place during scroll
    let originY: CGFloat
    if self.notificationDisplayed {
      originY = tableView.contentOffset.y
    } else {
      originY = tableView.contentOffset.y - notification.frame.height - 20
    }
    
    notification.frame.origin.y = originY
    tableView.bringSubviewToFront(notification)
    tableView.setNeedsDisplay()
  }
}
