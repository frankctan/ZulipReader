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


class NotificationNavViewController: SLKTextViewController {
  
  var notification = NotificationView()
  var sideMenuTableViewController: SideMenuTableViewController?
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    self.navigationControllerSettings()
    
    //notifications
    let screenBounds = UIScreen.mainScreen().bounds
    self.notification = NSBundle.mainBundle().loadNibNamed("NotificationView", owner: nil, options: nil)[0] as! NotificationView
    self.notification.frame.size.width = screenBounds.width
    self.notification.frame.origin = CGPoint(x: 0, y: -notification.frame.height - 20)
    
    self.tableViewSettings()
    self.textViewControllerSettings()
  }
  
  func
  
  func navigationControllerSettings() {
    if let navigationController = self.navigationController as? ScrollingNavigationController {
      navigationController.followScrollView(tableView, delay: 1.0)
    }
    
    //navBar right bar button items
    self.navigationController?.navigationBar.translucent = false
    let homeBarButton = UIBarButtonItem(image: UIImage(named: "house283-1"), style: .Plain, target: self, action: #selector(StreamTableViewController.homeButtonDidTouch(_:)))
    let scrollDownBarButton = UIBarButtonItem(image: UIImage(named: "DoubleDown - 1"), style: .Plain, target: self, action: #selector(StreamTableViewController.scrollDownDidTouch))
    navigationItem.setRightBarButtonItems([homeBarButton, scrollDownBarButton], animated: true)
    
    //navBar left bar button item - SideMenuNavigation
    let leftMenuBarButtonItem = UIBarButtonItem(image: UIImage(named: "menu"), style: .Plain, target: self.revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)))
    let sideMenuNavController = UINavigationController(rootViewController: self.sideMenuTableViewController!)
    self.revealViewController().rearViewController = sideMenuNavController
    self.navigationItem.setLeftBarButtonItem(leftMenuBarButtonItem, animated: true)
    
    //gesture Recognizer - SideMenuNavigation
    self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
  }
  
  func tableViewSettings() {
    tableView.estimatedRowHeight = 1000
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

//MARK: NavBar Target
extension StreamTableViewController {
  func scrollDownDidTouch() {
    guard let lastMessage = self.messages.flatten().last else {fatalError()}
    let lastIndex = NSIndexPath(forRow: lastMessage.row, inSection: lastMessage.section)
    tableView.scrollToRowAtIndexPath(lastIndex, atScrollPosition: .Middle, animated: true)
  }
  
  func homeButtonDidTouch(sender: AnyObject) {
    state = .Home
    let narrow = Narrow()
    self.focusAction(narrow)
    self.navigationController?.navigationBar.topItem?.title = "Stream"
    
    self.toggleNotification()
  }
  
  func focusAction(narrow: Narrow) {
    self.action = Action(narrow: narrow, action: .Focus)
    guard let data = data else {fatalError()}
    data.loadStreamMessages(self.action)
    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
  }
}

//MARK: SideMenuDelegate
extension StreamTableViewController: SideMenuDelegate {
  func sideMenuDidTouch(selection: String) {
    state = .Stream
    let narrow: Narrow
    switch selection {
    case "Private":
      let narrowString = "[[\"is\", \"\(selection.lowercaseString)\"]]"
      narrow = Narrow(narrowString: narrowString, type: .Private)
    case "Mentioned":
      let narrowString = "[[\"is\", \"\(selection.lowercaseString)\"]]"
      narrow = Narrow(narrowString: narrowString, mentioned: true)
    case "Logout":
      self.logout()
      return
    default:
      let narrowString = "[[\"stream\", \"\(selection)\"]]"
      narrow = Narrow(narrowString: narrowString, stream: selection)
    }
    
    self.navigationController?.navigationBar.topItem?.title = selection
    
    self.focusAction(narrow)
  }
}
