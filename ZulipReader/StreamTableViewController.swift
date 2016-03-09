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

class StreamTableViewController: SLKTextViewController {
  
  enum State {
    case Home, Stream, Subject
  }
  
  var state: State = .Home {
    didSet {
      if state == .Subject {
        self.setTextInputbarHidden(false, animated: true)
      }
      else {
        self.setTextInputbarHidden(true, animated: true)
      }
    }
  }
  var data: StreamController?
  var sideMenuTableViewController: SideMenuTableViewController?
  var messages = [[TableCell]]()
  var timer = NSTimer()
  var action = Action() {
    didSet {
      print(action)
    }
  }
  var refreshControl: UIRefreshControl?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.data = StreamController()
    self.sideMenuTableViewController = SideMenuTableViewController()
    guard let data = data else {fatalError()}
    data.delegate = self
    data.subscriptionDelegate = sideMenuTableViewController
    sideMenuTableViewController?.delegate = self
    tableViewSettings()
    state = .Home
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    if let navigationController = self.navigationController as? ScrollingNavigationController {
      navigationController.followScrollView(tableView, delay: 0.0)
    }
    self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
    
    print("in streamTableViewController:viewDidAppear")
    
    timer = NSTimer(timeInterval: 5.0, target: self, selector: "autoRefresh:", userInfo: nil, repeats: false)
    self.loadData()
  }
  
  func autoRefresh(timer: NSTimer) {
    print("shots fired")
    guard let data = data else {fatalError()}
    self.action.userAction = .Refresh
    data.loadStreamMessages(self.action)
  }
  
  func loadData() {
    guard let data = data else {fatalError()}
    if !data.isLoggedIn() {
      print("showing login screen")
      let controller = LoginViewController()
      presentViewController(controller, animated: true, completion: nil)
    }
    else {
      tableView.showLoading()
      data.register()
    }
  }
  
  //MARK: TableViewDelegate
  override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let headerType = messages[section][0].type
    
    //TODO: Is there anyway to refactor this?
    switch headerType {
    case .Stream:
      let cell = tableView.dequeueReusableCellWithIdentifier("StreamHeaderNavCell") as! StreamHeaderNavCell
      cell.configure(messages[section][0])
      cell.delegate = self
      let originalFrame = cell.frame
      cell.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: tableView.frame.width, height: originalFrame.height))
      let headerView = UIView(frame: cell.frame)
      headerView.addSubview(cell)
      return headerView
    case .Private:
      let cell = tableView.dequeueReusableCellWithIdentifier("StreamHeaderPrivateCell") as! StreamHeaderPrivateCell
      cell.configure(messages[section][0])
      cell.delegate = self
      let originalFrame = cell.frame
      cell.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: tableView.frame.width, height: originalFrame.height))
      let headerView = UIView(frame: cell.frame)
      headerView.addSubview(cell)
      return headerView
    }
  }
  
  override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 40.0
  }
  
  override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return UITableViewAutomaticDimension
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
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
  
  func refresh(refreshControl: UIRefreshControl) {
    print("refreshing!")
    self.refreshControl = refreshControl
    guard let data = data else {fatalError()}
    self.action.userAction = .ScrollUp
    data.loadStreamMessages(self.action)
  }
  
  func logout() {
    guard let data = data else {fatalError()}
    data.clearDefaults()
    self.timer.invalidate()
    self.timer = NSTimer()
    self.data = nil
    self.sideMenuTableViewController = nil
    self.refreshControl = nil
    self.state = .Home
    self.messages = [[TableCell]]()
    self.action = Action()
    tableView.reloadData()
    
    self.viewDidLoad()
    self.viewDidAppear(true)
  }
  
  //MARK: SLKTextViewController
  override func didPressRightButton(sender: AnyObject!) {
    self.textView.refreshFirstResponder()
    let sentMessage: String = self.textView.text
    let recipient = self.action.narrow.recipient
    let subject = self.action.narrow.subject
    
    let messagePost = MessagePost(content: sentMessage, recipient: recipient, subject: subject)
    
    self.action.userAction = .Refresh
    guard let data = data else {fatalError()}
    data.postMessage(messagePost, action: self.action)
    super.didPressRightButton(sender)
  }
  
  
  func tableViewSettings() {
    //General tableview settings
    self.navigationController?.navigationBar.topItem?.title = "Stream"
    
    tableView.estimatedRowHeight = 60
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.separatorStyle = UITableViewCellSeparatorStyle.None
    
    //TableView Cells
    tableView.registerNib(UINib(nibName: "StreamHeaderNavCell", bundle: nil), forCellReuseIdentifier: "StreamHeaderNavCell")
    tableView.registerNib(UINib(nibName: "StreamHeaderPrivateCell", bundle: nil), forCellReuseIdentifier: "StreamHeaderPrivateCell")
    tableView.registerNib(UINib(nibName: "StreamCell", bundle: nil), forCellReuseIdentifier: "StreamCell")
    tableView.registerNib(UINib(nibName: "StreamExtendedCell", bundle: nil), forCellReuseIdentifier: "StreamExtendedCell")
    
    //SLKTextViewController
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
    
    //Pull to Refresh
    let tableViewController = UITableViewController()
    tableViewController.tableView = self.tableView
    let refresh = UIRefreshControl()
    refresh.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
    tableViewController.refreshControl = refresh
    
    //Navigation Bar
    //Sticky headers follow the scrolling of the navbar
    self.navigationController?.navigationBar.translucent = false
    
    let rightHomeBarButtonItem = UIBarButtonItem(image: UIImage(named: "house283-1"), style: .Plain, target: self, action: "homeButtonDidTouch:")
    navigationItem.setRightBarButtonItem(rightHomeBarButtonItem, animated: true)
    
    //SWRevealViewController
    let leftMenuBarButtonItem = UIBarButtonItem(image: UIImage(named: "menu"), style: .Plain, target: self.revealViewController(), action: "revealToggle:")
    
    let sideMenuNavController = UINavigationController(rootViewController: self.sideMenuTableViewController!)
    
    self.revealViewController().rearViewController = sideMenuNavController
    
    self.navigationItem.setLeftBarButtonItem(leftMenuBarButtonItem, animated: true)
  }
}

//MARK: StreamControllerDelegate
extension StreamTableViewController: StreamControllerDelegate {
  func didFetchMessages() {
    tableView.hideLoading()
    NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
    self.refreshControl?.endRefreshing()
  }
  
  func didFetchMessages(messages: [[TableCell]], deletedSections: NSRange, insertedSections: NSRange, insertedRows: [NSIndexPath]) {
    tableView.hideLoading()
    print("# of old sections: \(self.messages.count)")
    self.messages = messages
    print("# of new sections: \(self.messages.count)")
    print("inserted sections: \(insertedSections)")
    print("deleted sections: \(deletedSections)")
    tableView.beginUpdates()
    tableView.deleteSections(NSIndexSet(indexesInRange: deletedSections), withRowAnimation: .None)
    tableView.insertSections(NSIndexSet(indexesInRange: insertedSections), withRowAnimation: .None)
    tableView.insertRowsAtIndexPaths(insertedRows, withRowAnimation: .None)
    tableView.endUpdates()
    
    //    self.tableView.scrollToRowAtIndexPath(insertedRows.last!, atScrollPosition: .Top, animated: true)
    
    self.refreshControl?.endRefreshing()
    
    NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
  }
}

//MARK: HomeBarButtonItem Target
extension StreamTableViewController {
  func homeButtonDidTouch(sender: AnyObject) {
    state = .Home
    let narrow = Narrow(type: .Stream)
    self.navigationController?.navigationBar.topItem?.title = "Stream"
    self.action = Action(narrow: narrow, action: .Focus)
    guard let data = data else {fatalError()}
    data.loadStreamMessages(self.action)
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
      narrow = Narrow(narrowString: narrowString, type: .Private, mentioned: nil)
    case "Mentioned":
      let narrowString = "[[\"is\", \"\(selection.lowercaseString)\"]]"
      narrow = Narrow(narrowString: narrowString, type: nil, mentioned: true)
    case "Logout":
      self.logout()
      return
    default:
      let narrowString = "[[\"stream\", \"\(selection)\"]]"
      narrow = Narrow(narrowString: narrowString, stream: selection)
    }
    
    self.navigationController?.navigationBar.topItem?.title = selection
    self.action = Action(narrow: narrow, action: .Focus)
    guard let data = data else {fatalError()}
    data.loadStreamMessages(action)
    tableView.showLoading()
  }
}

//MARK: StreamHeaderNavCellDelegate
extension StreamTableViewController: StreamHeaderNavCellDelegate {
  func narrowStream(stream: String) {
    state = .Stream
    
    let narrowString = "[[\"stream\", \"\(stream)\"]]"
    let narrow = Narrow(narrowString: narrowString, stream: stream)
    self.navigationController?.navigationBar.topItem?.title = stream
    
    self.action = Action(narrow: narrow, action: .Focus)
    guard let data = data else {fatalError()}
    data.loadStreamMessages(self.action)
    tableView.showLoading()
  }
  
  func narrowSubject(stream: String, subject: String) {
    state = .Subject
    
    let narrowString = "[[\"stream\", \"\(stream)\"],[\"topic\",\"\(subject)\"]]"
    let narrow = Narrow(narrowString: narrowString, stream: stream, subject: subject)
    self.navigationController?.navigationBar.topItem?.title = subject
    
    self.action = Action(narrow: narrow, action: .Focus)
    guard let data = data else {fatalError()}
    data.loadStreamMessages(self.action)
    tableView.showLoading()
  }
}

//MARK: StreamHeaderPrivateCellDelegate
extension StreamTableViewController: StreamHeaderPrivateCellDelegate {
  func narrowConversation(emails: [String]) {
    state = .Subject
    
    let emailString = emails.joinWithSeparator(",")
    let narrowString = "[[\"is\", \"private\"],[\"pm-with\",\"\(emailString)\"]]"
    let narrow = Narrow(narrowString: narrowString, privateRecipients: emails)
    
    self.action = Action(narrow: narrow, action: .Focus)
    guard let data = data else {fatalError()}
    data.loadStreamMessages(action)
    tableView.showLoading()
  }
}