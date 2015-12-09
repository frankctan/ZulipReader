//
//  StreamTableViewController.swift
//  ZulipReader
//
//  Created by Frank Tan on 11/23/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit

class StreamTableViewController: UITableViewController, StreamControllerDelegate {

    let data = StreamController()
    var messages = [[Cell]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableViewAutomaticDimension
        
        data.delegate = self
        data.getMessages()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    func streamController(messagesForTable: [[Cell]]) {
        messages = messagesForTable
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return messages.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let message = messages[indexPath.section][indexPath.row]
            let cell = tableView.dequeueReusableCellWithIdentifier("StreamTableViewCell") as! StreamTableViewCell
            cell.configureWithStream(message)
            return cell
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier("StreamTableViewHeaderNavCell") as! StreamTableViewHeaderNavCell
        cell.configureWithStream(messages[section][0])
        return cell
    }
}
