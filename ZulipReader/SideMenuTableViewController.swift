//
//  SideMenuTableViewController.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/15/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit

protocol SideMenuDelegate: class {
  func sideMenuDidTouch(selection: String)
}

class SideMenuTableViewController: UITableViewController {
  
  weak var delegate: SideMenuDelegate?
  
  var titleCells = ["Private", "Mentioned", "Logout"]
  var sectionTitles = ["General","Streams"]
  var subscriptions: [(String, String)]?
  
  override func viewDidLoad() {
    tableView.separatorStyle = UITableViewCellSeparatorStyle.None
    tableView.registerNib(UINib(nibName: "SideMenuCell", bundle: nil), forCellReuseIdentifier: "sideCell")
    self.navigationController?.navigationBar.translucent = false
    NSBundle.mainBundle().loadNibNamed("SideMenuTitle", owner: nil, options: nil)[0] as! SideMenuTitle
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    guard let navigationController = self.navigationController else {return}
    
    //a jenky way to ensure that text doesn't scroll all over the statusbar
    let navBarFrame = navigationController.navigationBar.frame
    let statusBarFrame = UIApplication.sharedApplication().statusBarFrame
    self.navigationController?.navigationBar.frame.origin.y = -navBarFrame.height + statusBarFrame.height
    tableView.frame.origin.y = statusBarFrame.height
    tableView.frame.size.height += navBarFrame.height
    
    //gets rid of bottom border
    self.navigationController?.navigationBar.shadowImage = UIImage()
    self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
  }
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 2
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return titleCells.count
    }
    guard let subscriptions = subscriptions else {return 0}
    return subscriptions.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("sideCell") as? SideMenuCell
    
    if indexPath.section == 0 {
      cell!.configureWithStream(titleCells[indexPath.row], color: "FFFFFF")
    }
    if indexPath.section == 1 {
      guard let subscriptions = subscriptions else {return cell!}
      let cellLabels = subscriptions[indexPath.row]
      cell!.configureWithStream(cellLabels.0, color: cellLabels.1)
    }
    return cell!
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let selection: String
    if indexPath.section == 0 {
      selection = titleCells[indexPath.row]
    }
    else {
      guard let subscriptions = self.subscriptions else {return}
      selection = subscriptions[indexPath.row].0
    }
    revealViewController().revealToggleAnimated(true)
    delegate?.sideMenuDidTouch(selection)
  }
  
  override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let header = NSBundle.mainBundle().loadNibNamed("SideMenuTitle", owner: nil, options: nil)[0] as! SideMenuTitle
    header.configure(sectionTitles[section])
    return header
  }
  
  override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 30
  }
}

extension SideMenuTableViewController: SubscriptionDelegate {
  func didFetchSubscriptions(subscriptions: [String : String]) {
    self.subscriptions = subscriptions.sort {$0.0 < $1.0}
    tableView.reloadData()
  }
}
