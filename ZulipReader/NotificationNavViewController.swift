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
  
  func setNavBarTitle(scrollDownFlag: Bool, title: String) {
    //scrollDownButton or title needs to be different
    guard scrollDownFlag != self.navBarTitle.scrollButtonHidden ||
      title != self.navBarTitle.title else {return}
    
    let animation = CATransition()
    animation.duration = 0.5
    animation.type = kCATransitionPush
    animation.subtype = kCATransitionFromTop
    animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
    self.navigationItem.titleView?.layer.addAnimation(animation, forKey: "titleAnimation")
    
    self.navBarTitle.configure(scrollDownFlag, title: title)
  }
  
  func scrollToBottom() {
    //always scroll to bottom by calculating the indexpath of the last row
    let section = self.tableView.numberOfSections - 1
    let row = self.tableView.numberOfRowsInSection(section) - 1
    let indexPath = NSIndexPath(forRow: row, inSection: section)
    self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Bottom)
    self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    
    self.setNavBarTitle(false, title: self.navBarTitle.title)
  }
  
  //MARK: Settings
  func navigationControllerSettings() {
    //pretty navbar title view
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
    //auto dismissal of navTitle notification icon
    guard self.navBarTitle.titleButton.imageView?.hidden == false else {return}

    let position = self.tableView.contentOffset.y
    let tableHeight = self.tableView.frame.height
    
    let section = self.tableView.numberOfSections - 1
    let row = self.tableView.numberOfRowsInSection(section) - 1
    let indexPath = NSIndexPath(forRow: row, inSection: section)
    let rectForLastIndexPath = self.tableView.rectForRowAtIndexPath(indexPath)
    
    if position + tableHeight > rectForLastIndexPath.origin.y + rectForLastIndexPath.height {
      print("position: \(position) + tableHeight: \(tableHeight) > originy: \(rectForLastIndexPath.origin.y) + rectForLastIndexPath: \(rectForLastIndexPath.height)")
      self.setNavBarTitle(false, title: self.navBarTitle.title)
    }
  }
}
