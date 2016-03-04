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
  
  let data = StreamController()
  let sideMenuTableViewController = SideMenuTableViewController()
  var messages = [[TableCell]]()
  
  enum State {
    case Home, Narrow
  }
  
  var state: State = .Home
  var narrow = Narrow()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
    data.delegate = self
    data.subscriptionDelegate = sideMenuTableViewController
    sideMenuTableViewController.delegate = self
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
    loadData()
//    let timer = NSTimer(timeInterval: 5.0, target: self, selector: "autoRefresh:", userInfo: nil, repeats: true)
//    NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
    tableView.showLoading()
  }
  
  func autoRefresh(timer: NSTimer) {
    print("shots fired")
    data.loadStreamMessages(Action(narrow: self.narrow, action: .Refresh))
  }
  
  func loadData() {
    if !data.isLoggedIn() {
      print("showing login screen")
      let storyBoard = UIStoryboard(name: "Main", bundle: nil)
      let controller = storyBoard.instantiateViewControllerWithIdentifier("LoginViewController")
      presentViewController(controller, animated: true, completion: nil)
    }
    else {
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
    return 27.0
  }
  
  override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return UITableViewAutomaticDimension
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
    data.loadStreamMessages(Action(narrow: self.narrow, action: .ScrollUp))
    refreshControl.endRefreshing()
  }
  
  func tableViewSettings() {
    //General tableview settings
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
    self.textView.placeholder = "Message"
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
//    self.revealViewController().rearViewRevealWidth = 100
    self.revealViewController().rearViewController = self.sideMenuTableViewController
    
    navigationItem.setLeftBarButtonItem(leftMenuBarButtonItem, animated: true)
  }
}

//MARK: StreamControllerDelegate
extension StreamTableViewController: StreamControllerDelegate {
  func didFetchMessages() {
    tableView.hideLoading()
  }
  
  func didFetchMessages(messages: [[TableCell]], deletedSections: NSRange, insertedSections: NSRange, insertedRows: [NSIndexPath]) {
    tableView.hideLoading()
    print("# of old sections: \(self.messages.count)")
    self.messages = messages
    print("# of new sections: \(self.messages.count)")
    print("inserted sections: \(insertedSections)")
    print("deleted sections: \(deletedSections)")
    tableView.beginUpdates()
    tableView.deleteSections(NSIndexSet(indexesInRange: deletedSections), withRowAnimation: .Automatic)
    tableView.insertSections(NSIndexSet(indexesInRange: insertedSections), withRowAnimation: .Automatic)
    tableView.insertRowsAtIndexPaths(insertedRows, withRowAnimation: .Automatic)
    tableView.endUpdates()
    
    tableView.scrollToRowAtIndexPath(insertedRows.last!, atScrollPosition: .Top, animated: true)
    
  }
}

//MARK: HomeBarButtonItem Target
extension StreamTableViewController {
  func homeButtonDidTouch(sender: AnyObject) {
    state = .Home
    narrow = Narrow(type: .Stream)
    let action = Action(narrow: self.narrow, action: .Focus)
    data.loadStreamMessages(action)
  }
}

//MARK: SideMenuDelegate
extension StreamTableViewController: SideMenuDelegate {
  func sideMenuDidNarrow(narrow: Narrow) {
    state = .Narrow
    self.narrow = narrow
    let action = Action(narrow: self.narrow, action: .Focus)
    data.loadStreamMessages(action)
    tableView.showLoading()
  }
}

//MARK: StreamHeaderNavCellDelegate
extension StreamTableViewController: StreamHeaderNavCellDelegate {
  func narrowStream(stream: String) {
    state = .Narrow
    
    let narrowString = "[[\"stream\", \"\(stream)\"]]"
    self.narrow = Narrow(narrowString: narrowString, stream: stream)

    let action = Action(narrow: self.narrow, action: .Focus)
    data.loadStreamMessages(action)
    tableView.showLoading()
  }
  
  func narrowSubject(stream: String, subject: String) {
    state = .Narrow
    
    let narrowString = "[[\"stream\", \"\(stream)\"],[\"topic\",\"\(subject)\"]]"
    self.narrow = Narrow(narrowString: narrowString, stream: stream, subject: subject)
    
    let action = Action(narrow: self.narrow, action: .Focus)
    data.loadStreamMessages(action)
    tableView.showLoading()
  }
}

//MARK: StreamHeaderPrivateCellDelegate
extension StreamTableViewController: StreamHeaderPrivateCellDelegate {
  func narrowConversation(emails: [String]) {
    state = .Narrow
    
    let emailString = emails.joinWithSeparator(",")
    let narrowString = "[[\"is\", \"private\"],[\"pm-with\",\"\(emailString)\"]]"
    narrow = Narrow(narrowString: narrowString, privateRecipients: emails)
    
    let action = Action(narrow: self.narrow, action: .Focus)
    data.loadStreamMessages(action)
    tableView.showLoading()
  }
}