//
//  SideMenuTableViewController.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/15/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import AMScrollingNavbar

protocol SideMenuDelegate: class {
  func sideMenuDidNarrow(narrow: Narrow)
  func sideMenuDidLogout()
}

class SideMenuTableViewController: UITableViewController {
  
  weak var delegate: SideMenuDelegate?
  
  var titleCells = ["Private", "Mentioned", "Logout"]
  var sectionTitles = ["GENERAL","STREAMS"]
  var subscriptions: [(String, String)]?
  
  override func viewDidLoad() {
    tableView.separatorStyle = UITableViewCellSeparatorStyle.None
    tableView.registerNib(UINib(nibName: "SideMenuCell", bundle: nil), forCellReuseIdentifier: "sideCell")
    self.navigationController?.navigationBar.translucent = false
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    guard let navigationController = self.navigationController else {return}
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
    let userSelection: String
    let narrow: Narrow
    if indexPath.section == 0 {
      userSelection = titleCells[indexPath.row]
      let narrowString = "[[\"is\", \"\(userSelection.lowercaseString)\"]]"
      switch userSelection {
        case "Private":
          narrow = Narrow(narrowString: narrowString, type: .Private, mentioned: nil)
        case "Mentioned":
          narrow = Narrow(narrowString: narrowString, type: nil, mentioned: true)
        case "Logout":
          revealViewController().revealToggleAnimated(true)
          self.delegate?.sideMenuDidLogout()
        return
      default:
        fatalError("Side Menu Error")
      }
    }
    else {
      userSelection = subscriptions![indexPath.row].0
      let narrowString = "[[\"stream\", \"\(userSelection)\"]]"
      narrow = Narrow(narrowString: narrowString, stream: userSelection)
    }
    
    revealViewController().revealToggleAnimated(true)
    delegate?.sideMenuDidNarrow(narrow)
  }
  
  override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return sectionTitles[section]
  }
}

extension SideMenuTableViewController: SubscriptionDelegate {
  func didFetchSubscriptions(subscriptions: [String : String]) {
    self.subscriptions = subscriptions.sort {$0.0 < $1.0}
  }
}
