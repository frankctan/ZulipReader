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

class StreamTableViewController: SLKTextViewController {
  
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
  var messages: [[TableCell]] = []
  
  required init!(coder decoder: NSCoder!) {
    super.init(coder: decoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    data.delegate = self
    tableViewSettings()

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
    }
    else {
      data.loadStreamMessages()
    }
  }

  //MARK: TableViewDelegate
  override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let headerType = messages[section][0].type
    
    //TODO: Is there anyway to refactor this?
    switch headerType {
    case "stream":
      let cell = tableView.dequeueReusableCellWithIdentifier("StreamHeaderNavCell") as! StreamHeaderNavCell
      cell.configure(messages[section][0])
      cell.delegate = self
      return cell
    case "private":
      let cell = tableView.dequeueReusableCellWithIdentifier("StreamHeaderPrivateCell") as! StreamHeaderPrivateCell
      cell.configure(messages[section][0])
      cell.delegate = self
      return cell
    default: fatalError()
    }
  }
  
  override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 27.0
  }
  
  //MARK: TableViewDataSource
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return messages.count
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return messages[section].count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let message = messages[indexPath.section][indexPath.row]
    let cell: ZulipTableViewCell
    
    switch message.cellType {
    case .StreamCell:
      cell = tableView.dequeueReusableCellWithIdentifier(message.cellType.string) as! StreamCell
    case .ExtendedCell:
      cell = tableView.dequeueReusableCellWithIdentifier(message.cellType.string) as! StreamExtendedCell
    }
    cell.configure(message)
    return cell
  }
  
  func tableViewSettings() {
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
  }
}

//MARK: StreamControllerDelegate
extension StreamTableViewController: StreamControllerDelegate {
  func statusUpdate(flag: Bool) {
    if flag {
      loadData()
    }
  }
  
  func didFetchMesssages(messages: [[TableCell]]) {
    self.messages = messages
    tableView.hideLoading()
    tableView.reloadData()
  }
}

//MARK: StreamHeaderNavCellDelegate
extension StreamTableViewController: StreamHeaderNavCellDelegate {
  func narrowStream(stream: String) {
    let narrow = "[[\"stream\", \"\(stream)\"]]"
    data.loadNarrowMessages(narrow)
    tableView.showLoading()
  }
  
  func narrowSubject(stream: String, subject: String) {
    let narrow = "[[\"stream\", \"\(stream)\"],[\"topic\",\"\(subject)\"]]"
    data.loadNarrowMessages(narrow)
    tableView.showLoading()
  }
}

//MARK: StreamHeaderPrivateCellDelegate
extension StreamTableViewController: StreamHeaderPrivateCellDelegate {
  func narrowConversation(emails: String) {
    let narrow = "[[\"is\", \"private\"],[\"pm-with\",\"\(emails)\"]]"
    data.loadNarrowMessages(narrow)
    tableView.showLoading()
  }
}

