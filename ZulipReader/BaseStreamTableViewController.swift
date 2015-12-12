//
//  BaseStreamTableViewController.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/12/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import AMScrollingNavbar

class BaseStreamTableViewController: UITableViewController {
    let data = StreamController()
    var messages = [[Cell]]()
    var narrowParams: [[String]]?
    var narrowTitle = "Stream"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableViewAutomaticDimension
        
        data.getStreamMessages(narrowParams)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let navigationController = self.navigationController as? ScrollingNavigationController {
            navigationController.followScrollView(tableView, delay: 50.0)
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return messages.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let message = messages[indexPath.section][indexPath.row]
        var previousMessage = Cell()
        
        if indexPath.row > 0 {
            previousMessage = messages[indexPath.section][indexPath.row - 1]
        }
        
        if message.name == previousMessage.name {
            let cell = tableView.dequeueReusableCellWithIdentifier("StreamTableViewExtendedCell") as! StreamTableViewExtendedCell
            cell.configureWithStream(message)
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("StreamTableViewCell") as! StreamTableViewCell
            cell.configureWithStream(message)
            return cell
        }
    }
    
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier("StreamTableViewHeaderNavCell") as! StreamTableViewHeaderNavCell
        cell.configureWithStream(messages[section][0])
        return cell
    }

}
