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
  
  var blurEffectView = UIView()
  var inTransition = false
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    //notification settings
    let screenBounds = UIScreen.mainScreen().bounds
    self.notification = NSBundle.mainBundle().loadNibNamed("NotificationView", owner: nil, options: nil)[0] as! NotificationView
    self.notification.delegate = self
    
    let origin = CGPoint(x: 0.0, y: -30)
    let size = CGSize(width: screenBounds.width, height: 30)
    self.notification.frame = CGRect(origin: origin, size: size)

    print("self.notification size - \(self.notification.frame)")
    self.notification.backgroundColor = UIColor.yellowColor()
    
    self.tableView.superview!.addSubview(self.notification)
    self.tableView.superview!.bringSubviewToFront(self.notification)
    //TODO: make this true
    self.notification.hidden = true
    
    print("self.notification size - \(self.notification.frame)")
    
    //configure view
    self.navigationControllerSettings()
    self.tableViewSettings()
    self.textViewControllerSettings()
    
    //transition settings
    let blurEffect = UIBlurEffect(style: .Light)
    self.blurEffectView = UIVisualEffectView(effect: blurEffect)
    self.blurEffectView.frame = self.view.bounds
    self.blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
  }
  
  func transitionToBlur(flag: Bool) {
    guard flag != self.inTransition else {return}
    self.inTransition = flag
    if flag {
      UIView.transitionWithView(self.view, duration: 0.2, options: .TransitionCrossDissolve, animations: {
        self.view.addSubview(self.blurEffectView)
        }, completion: {_ in self.blurEffectView.showLoading()})
    } else {
      UIView.transitionWithView(self.view, duration: 0.2, options: .TransitionCrossDissolve, animations: {
        self.blurEffectView.removeFromSuperview()
        }, completion: {_ in self.blurEffectView.hideLoading()})
    }
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

    //TODO: why do I need to redefine the notification frame size?
    let screenBounds = UIScreen.mainScreen().bounds
    let size = CGSize(width: screenBounds.width, height: 30)
    self.notification.frame.size = size
    print("self.notification size - \(self.notification.frame)")
    
    
    let notificationHeight = self.notification.frame.height
    
    if self.notificationDisplayed {
      //retract notification
      self.notificationDisplayed = false
      originY = -notificationHeight
      tableViewInset = 0
    }
    else {
      //display notification
      self.notification.hidden = false
      self.tableView.bringSubviewToFront(self.notification)
      self.tableView.setNeedsDisplay()
      
      self.notificationDisplayed = true
      originY = 0
      tableViewInset = notificationHeight
    }
    
    print("NotificationViewController: animating")
    
    UIView.animateWithDuration(0.2, delay: 0.0, options: [.AllowUserInteraction, .CurveEaseIn], animations: {
      self.notification.frame.origin.y = originY
      self.tableView.contentInset.top = tableViewInset
      }, completion: {_ in
        self.view.setNeedsDisplay()
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
    let fadeTextAnimation = CATransition()
    fadeTextAnimation.duration = 0.5
    fadeTextAnimation.type = kCATransitionFromTop
    
    navigationController?.navigationBar.layer.addAnimation(fadeTextAnimation, forKey: "fadeText")
    
    self.navigationItem.title = "Stream"
    
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
    tableView.alwaysBounceVertical = true
    tableView.bounces = true
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
//    let originY: CGFloat
//    if self.notificationDisplayed {
//      originY = tableView.contentOffset.y
//    } else {
//      originY = tableView.contentOffset.y - notification.frame.height - 20
//    }
//    
//    notification.frame.origin.y = originY
//    tableView.bringSubviewToFront(notification)
//    tableView.setNeedsDisplay()
  }
}
