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
  
  let data = StreamController()
  var messages = [[TableCell]]()
  
  required init!(coder decoder: NSCoder!) {
    super.init(coder: decoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    data.delegate = self
    tableViewSettings()
    
    let rightHomeBarButtonItem = UIBarButtonItem(image: UIImage(named: "house283-1"), style: .Plain, target: self, action: "homeButtonDidTouch:")
    navigationItem.setRightBarButtonItem(rightHomeBarButtonItem, animated: true)
    
    let leftMenuBarButtonItem = UIBarButtonItem(image: UIImage(named: "menu"), style: .Plain, target: self.revealViewController(), action: "revealToggle:")
    navigationItem.setLeftBarButtonItem(leftMenuBarButtonItem, animated: true)
    self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
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
      data.register()
    }
  }
  
  //MARK: HomeBarButtonItem Target
  func homeButtonDidTouch(sender: AnyObject) {
    data.loadStreamMessages(UserAction.Home)
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
      let view = UIView(frame: cell.frame)
      view.addSubview(cell)
      return view
    case "private":
      let cell = tableView.dequeueReusableCellWithIdentifier("StreamHeaderPrivateCell") as! StreamHeaderPrivateCell
      cell.configure(messages[section][0])
      cell.delegate = self
      let view = UIView(frame: cell.frame)
      view.addSubview(cell)
      return view
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
  
  //MARK: UIScrollViewDelegate
    override func scrollViewDidScroll(scrollView: UIScrollView) {
      // If within half a screen of the top, load more.
      guard scrollView.contentOffset.y + scrollView.bounds.height < scrollView.contentSize.height - view.bounds.height / 2 else { return }
  
      data.loadStreamMessages(UserAction.ScrollUp)
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
  func didFetchMesssages(messages: [[TableCell]], newMessages indexPaths: (inserted: [NSIndexPath], deleted: [NSIndexPath]), action: UserAction) {
    tableView.hideLoading()
    let oldMessageCount = self.messages.count
    
    self.messages = messages
    print("new messages: \(messages.count)")
    let inserted = indexPaths.inserted
    print("inserted: \n \(inserted.map {$0.section}) \n \(inserted.map {$0.row})")
    let insertedSections = NSMutableIndexSet()
    
    var sectionsToBeInserted = Set(inserted.map {$0.section})
    
    //delete unnecessary section insertions
    if sectionsToBeInserted.count + oldMessageCount > messages.count {
      sectionsToBeInserted.remove(sectionsToBeInserted.maxElement()!)
    }
    
    for section in sectionsToBeInserted {
      insertedSections.addIndex(section)
    }
    
    //deletions occur on UserAction - Home and Narrow
    let deleted = indexPaths.deleted
    let deletedSections = NSMutableIndexSet()
    if deleted.count > 0 {
      let sectionsToBeDeleted = Set(deleted.map {$0.section})
      for section in sectionsToBeDeleted {
        deletedSections.addIndex(section)
      }
    }

    tableView.beginUpdates()
    tableView.deleteSections(deletedSections, withRowAnimation: .None)
//    tableView.deleteRowsAtIndexPaths(deleted, withRowAnimation: .None)
    tableView.insertSections(insertedSections, withRowAnimation: .None)
    tableView.insertRowsAtIndexPaths(inserted, withRowAnimation: .None)
    tableView.endUpdates()
    
    switch action {
    case .Narrow(_), .Register:
      let sectionMax = messages.count - 1
      let rowMax = messages[sectionMax].count - 1
      tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: rowMax, inSection: sectionMax), atScrollPosition: .Bottom, animated: false)
    default: break
    }
  }
}

//MARK: StreamHeaderNavCellDelegate
extension StreamTableViewController: StreamHeaderNavCellDelegate {
  func narrowStream(stream: String) {
    print("narrowing stream")
    let narrow = "[[\"stream\", \"\(stream)\"]]"
    data.loadStreamMessages(UserAction.Narrow(narrow: narrow))
    tableView.showLoading()
  }
  
  func narrowSubject(stream: String, subject: String) {
    let narrow = "[[\"stream\", \"\(stream)\"],[\"topic\",\"\(subject)\"]]"
    data.loadStreamMessages(UserAction.Narrow(narrow: narrow))
    tableView.showLoading()
  }
}

//MARK: StreamHeaderPrivateCellDelegate
extension StreamTableViewController: StreamHeaderPrivateCellDelegate {
  func narrowConversation(emails: String) {
    let narrow = "[[\"is\", \"private\"],[\"pm-with\",\"\(emails)\"]]"
    data.loadStreamMessages(UserAction.Narrow(narrow: narrow))
    tableView.showLoading()
  }
}