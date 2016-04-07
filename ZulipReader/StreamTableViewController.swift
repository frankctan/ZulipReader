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
  
  var state: State = .Home
  var data: StreamController?
  var sideMenuTableViewController: SideMenuTableViewController?
  var messages = [[TableCell]]()
  var action = Action()
  
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
    tableView.scrollsToTop = true
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    if let navigationController = self.navigationController as? ScrollingNavigationController {
      navigationController.followScrollView(tableView, delay: 0.0)
    }
    self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
    
    self.loadData()
    
    //MARK: notification trial!!!
    //How to add badge to the home icon to indicate unread messages?
    let superView = self.view
    guard let navController = self.navigationController else {fatalError()}
    let navBarHeight = navController.navigationBar.frame.height
    let viewWidth = superView.frame.width
    let notificationSize = CGSize(width: viewWidth, height: navBarHeight)
    let origin = CGPoint(x: 0.0, y: -navBarHeight)
    let notification = UIView(frame: CGRect(origin: origin, size: notificationSize))
    
    notification.backgroundColor = UIColor.yellowColor()
    superView.addSubview(notification)
    
    UIView.animateWithDuration(0.5, delay: 2.0, options: [.AllowUserInteraction, .CurveEaseIn], animations: {
      superView.frame.origin.y += navBarHeight
      }, completion: {_ in
        UIView.animateWithDuration(0.5, delay: 4.0, options: [.AllowUserInteraction, .CurveEaseIn], animations: {
          superView.frame.origin.y -= navBarHeight
          }, completion: nil)
    })
  }
  
  func loadData() {
    guard let data = data else {fatalError()}
    if !data.isLoggedIn() {
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
    let headerCell = messages[section][0]
    let headerType = headerCell.type
    let cell: ZulipTableViewCell
    
    switch headerType {
    case .Stream:
      cell = tableView.dequeueReusableCellWithIdentifier("StreamHeaderNavCell") as! StreamHeaderNavCell
      let navCell = cell as! StreamHeaderNavCell
      navCell.delegate = self
      
    case .Private:
      cell = tableView.dequeueReusableCellWithIdentifier("StreamHeaderPrivateCell") as! StreamHeaderPrivateCell
      let privateCell = cell as! StreamHeaderPrivateCell
      privateCell.delegate = self
    }
    
    cell.configure(headerCell)
    return configureHeaderView(cell)
  }
  
  func configureHeaderView(cell: ZulipTableViewCell) -> UIView {
    let originalFrame = cell.frame
    cell.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: tableView.frame.width, height: originalFrame.height))
    let headerView = UIView(frame: cell.frame)
    headerView.addSubview(cell)
    return headerView
  }
  
  override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 27.0
  }
  
  override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 1000
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
    self.refreshControl = refreshControl
    guard let data = data else {fatalError()}
    self.action.userAction = .ScrollUp
    data.loadStreamMessages(self.action)
  }
  
  func logout() {
    guard let data = data else {fatalError()}
    data.clearDefaults()
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
  //Right button only appears in .Subject
  override func didPressRightButton(sender: AnyObject!) {
    self.textView.refreshFirstResponder()
    let sentMessage: String = self.textView.text
    
    //Either pmWith or stream will be empty []
    let pmWith = self.action.narrow.pmWith
    let stream = self.action.narrow.stream
    let recipient = pmWith + stream
    
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
    
    tableView.estimatedRowHeight = 500
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
    refresh.addTarget(self, action: #selector(StreamTableViewController.refresh(_:)), forControlEvents: .ValueChanged)
    tableViewController.refreshControl = refresh
    
    //Navigation Bar
    //Sticky headers follow the scrolling of the navbar
    self.navigationController?.navigationBar.translucent = false
    let rightHomeBarButtonItem = UIBarButtonItem(image: UIImage(named: "house283-1"), style: .Plain, target: self, action: #selector(StreamTableViewController.homeButtonDidTouch(_:)))
    navigationItem.setRightBarButtonItem(rightHomeBarButtonItem, animated: true)
    
    //SWRevealViewController
    let leftMenuBarButtonItem = UIBarButtonItem(image: UIImage(named: "menu"), style: .Plain, target: self.revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)))
    let sideMenuNavController = UINavigationController(rootViewController: self.sideMenuTableViewController!)
    self.revealViewController().rearViewController = sideMenuNavController
    self.navigationItem.setLeftBarButtonItem(leftMenuBarButtonItem, animated: true)
  }
}

//MARK: ScrollViewControllerDelegate
extension StreamTableViewController {
  override func scrollViewDidScroll(scrollView: UIScrollView) {
    //    print("scrollView contentsize: \(scrollView.contentSize)")
    //    print("tableView contentsize: \(tableView.contentSize)")
    //    print("scrollView contentOffset: \(scrollView.contentOffset)")
    //    print("tableView contentOffset: \(tableView.contentOffset)")
  }
}

//MARK: StreamControllerDelegate
extension StreamTableViewController: StreamControllerDelegate {
  func didFetchMessages() {
    if let refresh = self.refreshControl {
      if refresh.refreshing {
        self.refreshControl!.endRefreshing()
      }
    }
    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
  }
  
  func didFetchMessages(messages: [[TableCell]], deletedSections: NSRange, insertedSections: NSRange, insertedRows: [NSIndexPath]) {
    self.tableView.hideLoading()
    print("UITVC: old sections: \(self.messages.count)")
    self.messages = messages
    
    print("UITVC: new sections: \(self.messages.count)")
    print("UITVC: inserted sections: \(insertedSections)")
    print("UITVC: deleted sections: \(deletedSections)")
    
    self.tableView.beginUpdates()
    self.tableView.deleteSections(NSIndexSet(indexesInRange: deletedSections), withRowAnimation: .Automatic)
    self.tableView.insertSections(NSIndexSet(indexesInRange: insertedSections), withRowAnimation: .Automatic)
    self.tableView.insertRowsAtIndexPaths(insertedRows, withRowAnimation: .Automatic)
    self.tableView.endUpdates()
    
    if let refresh = self.refreshControl  {
      if refresh.refreshing {
        self.refreshControl!.endRefreshing()
      }
    }
    
    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    
    print("\n# of tableView Mesages: \(self.messages.flatten().count)")
    self.tableView.scrollToRowAtIndexPath(insertedRows.last!, atScrollPosition: .Top, animated: true)
    
    switch self.state {
    case .Subject:
      self.setTextInputbarHidden(false, animated: true)
    default:
      self.setTextInputbarHidden(true, animated: true)
    }
  }
}

//MARK: HomeBarButtonItem Target
extension StreamTableViewController {
  func homeButtonDidTouch(sender: AnyObject) {
    state = .Home
    let narrow = Narrow()
    self.navigationController?.navigationBar.topItem?.title = "Stream"
    self.focusAction(narrow)
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

//MARK: StreamHeaderNavCellDelegate
extension StreamTableViewController: StreamHeaderNavCellDelegate {
  func narrowStream(stream: String) {
    print("tapped!")
    state = .Stream
    
    let narrowString = "[[\"stream\", \"\(stream)\"]]"
    let narrow = Narrow(narrowString: narrowString, stream: stream)
    self.navigationController?.navigationBar.topItem?.title = stream
    
    self.focusAction(narrow)
  }
  
  func narrowSubject(stream: String, subject: String) {
    state = .Subject
    
    let narrowString = "[[\"stream\", \"\(stream)\"],[\"topic\",\"\(subject)\"]]"
    let narrow = Narrow(narrowString: narrowString, stream: stream, subject: subject)
    self.navigationController?.navigationBar.topItem?.title = subject
    
    self.focusAction(narrow)
  }
}

//MARK: StreamHeaderPrivateCellDelegate
extension StreamTableViewController: StreamHeaderPrivateCellDelegate {
  func narrowConversation(message: TableCell) {
    state = .Subject
    
    let pmWith = message.pmWith.sort()
    let emailString = pmWith.joinWithSeparator(",")
    let narrowString = "[[\"is\", \"private\"],[\"pm-with\",\"\(emailString)\"]]"
    let narrow = Narrow(narrowString: narrowString, pmWith: pmWith)
    self.navigationController?.navigationBar.topItem?.title = "Private Messages"
    
    self.focusAction(narrow)
  }
}