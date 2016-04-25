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
  var navBarTitle = NavBarTitle()
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
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
      UIView.transitionWithView(self.view, duration: 0.3, options: .TransitionCrossDissolve, animations: {
        self.view.addSubview(self.blurEffectView)
        }, completion: {_ in self.blurEffectView.showLoading()})
    } else {
      UIView.transitionWithView(self.view, duration: 0.3, options: .TransitionCrossDissolve, animations: {
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
  
  func scrollToBottom() {
    tableView.setNeedsLayout()
    let scrollToHeight = tableView.contentSize.height - tableView.frame.height
    let scrollToRect = CGRect(x: 0.0, y: scrollToHeight, width: tableView.frame.width, height: tableView.frame.height)
    tableView.scrollRectToVisible(scrollToRect, animated: true)
    
    let titleAnimation = CATransition()
    titleAnimation.duration = 0.5
    titleAnimation.type = kCATransitionPush
    
    navigationController?.navigationBar.layer.addAnimation(titleAnimation, forKey: "fadeText")
    self.navBarTitle.configure(false, title: self.navBarTitle.titleButton.currentTitle!)
  }
  
  //MARK: Settings
  func navigationControllerSettings() {
    //pretty navbar title view
    //TOOD: I have to set up the animation  every time I use it. why?
    let titleAnimation = CATransition()
    titleAnimation.duration = 0.2
    titleAnimation.type = kCATransitionFromTop
    navigationController?.navigationBar.layer.addAnimation(titleAnimation, forKey: "fadeText")
    
    self.navBarTitle = NSBundle.mainBundle().loadNibNamed("NavBarTitle", owner: nil, options: nil)[0] as! NavBarTitle
    self.navBarTitle.titleButton.addTarget(self, action: #selector(scrollToBottom), forControlEvents: UIControlEvents.TouchDown)
    
    self.navBarTitle.configure(false, title: "Stream")
    self.navigationItem.titleView = self.navBarTitle
    
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
  
  override func scrollViewDidScroll(scrollView: UIScrollView) {
    guard self.navBarTitle.titleButton.imageView != nil else {return}
    
    //TODO: contentHeight and position reset themselves after new messages are loaded - not sure how to reliably dismiss the down arrow
    
//    self.tableView.layoutIfNeeded()
//    let position = self.tableView.contentOffset.y
//    let contentHeight = self.tableView.contentSize.height
//    let tableHeight = self.tableView.frame.height
//    
//    print("scroll position: \(position)")
//    print("contentHeight: \(contentHeight)")
//    print("tableHeight: \(tableHeight)")
//    
//    if position + tableHeight > contentHeight + 250 {
//      let fadeTextAnimation = CATransition()
//      fadeTextAnimation.duration = 0.2
//      fadeTextAnimation.type = kCATransitionFromTop
//      navigationController?.navigationBar.layer.addAnimation(fadeTextAnimation, forKey: "fadeText")
//      
//      self.navBarTitle.configure(false, title: navBarTitle.titleButton.currentTitle!)
//    }
    
  }
}
