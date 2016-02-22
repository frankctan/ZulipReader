//
//  StreamTableViewController.swift
//  ZulipReader
//
//  Created by Frank Tan on 11/23/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import AMScrollingNavbar
import SlackTextViewController

var State = ""

class StreamTableViewController: SLKTextViewController, StreamControllerDelegate {
  
  //TODO: create a new view for navigation!
  @IBOutlet weak var menuButton: UIBarButtonItem!
//
//  @IBAction func homeButtonDidTouch(sender: AnyObject) {
//    State = "stream"
//    narrowTitle = "Stream"
//    narrowParams = nil
//    self.data.getStreamMessages(narrowParams)
//    self.setTextInputbarHidden(true, animated: true)
//  }
  
  let data = StreamController()
//  var messages = [[Cell]]()
//  
  var narrowParams: [[String]]?
  var narrowTitle = "Stream"
  var narrowType = ""
  var narrowSubject:String?
  var narrowRecipient = [String]()
//
  var longPollFlag = false
//
  var dataSource: TableViewControllerDataSource!
  var tableDelegate: TableViewDelegate!
//
  required init!(coder decoder: NSCoder!) {
    super.init(coder: decoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    data.delegate = self
    
    tableView.estimatedRowHeight = 60
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.separatorStyle = UITableViewCellSeparatorStyle.None
    
    tableView.registerNib(UINib(nibName: "StreamHeaderNavCell", bundle: nil), forCellReuseIdentifier: "StreamHeaderNavCell")
    tableView.registerNib(UINib(nibName: "StreamHeaderPrivateCell", bundle: nil), forCellReuseIdentifier: "StreamHeaderPrivateCell")
    tableView.registerNib(UINib(nibName: "StreamCell", bundle: nil), forCellReuseIdentifier: "StreamCell")
    tableView.registerNib(UINib(nibName: "StreamExtendedCell", bundle: nil), forCellReuseIdentifier: "StreamExtendedCell")
    

    self.setTextInputbarHidden(true, animated: false)
    self.bounces = true
    self.shakeToClearEnabled = true
    self.keyboardPanningEnabled = true
    self.inverted = false
    self.textView.placeholder = "Message"
    self.textView.placeholderColor = UIColor.lightGrayColor()
    self.textInputbar.autoHideRightButton = true
    self.typingIndicatorView.canResignByTouch = true
    self.rightButton.setTitle("Send", forState: UIControlState.Normal)
    
    if self.revealViewController() != nil {
      menuButton.target = self.revealViewController()
      menuButton.action = "revealToggle:"
      self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
    }
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    if let navigationController = self.navigationController as? ScrollingNavigationController {
      navigationController.followScrollView(tableView, delay: 0.0)
    }
    print("in streamTableViewController:viewDidAppear")
    tableView.showLoading()
    loadData()
  }
  
  func loadData() {
    if !data.isLoggedIn() {
      print("showing login screen")
      let storyBoard = UIStoryboard(name: "Main", bundle: nil)
      let controller = storyBoard.instantiateViewControllerWithIdentifier("LoginViewController")
      presentViewController(controller, animated: true, completion: nil)
    } else {
      data.loadMessages()
    }
  }
  
  //MARK: -StreamControllerDelegate
  func statusUpdate(flag: Bool) {
    if flag {
      loadData()
    }
  }
  
  func didFetchMesssages(messages: [[TableCell]]) {
    dataSource.messages = messages
    tableDelegate.messages = messages
  }
}

