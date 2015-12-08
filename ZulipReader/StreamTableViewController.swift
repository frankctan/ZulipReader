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
    var messages = [Cell]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        
        data.delegate = self
        data.getMessages()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    func streamController(cellMessages: [Cell]) {
        messages = cellMessages
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count/2
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        switch message {
        case is StreamHeaderCell:
            let cell = tableView.dequeueReusableCellWithIdentifier("StreamTableViewHeaderNavCell") as! StreamTableViewHeaderNavCell
            cell.configureWithStream(message as! StreamHeaderCell)
            return cell
        case is UserHeaderCell:
            let cell = tableView.dequeueReusableCellWithIdentifier("StreamTableViewHeaderCell") as! StreamTableViewHeaderCell
            cell.configureWithStream(message as! UserHeaderCell)
            return cell
        case is MessageCell:
            let cell = tableView.dequeueReusableCellWithIdentifier("StreamTableViewCell") as! StreamTableViewCell
            cell.configureWithStream(message as! MessageCell)
            return cell
        default:
            print("Something broke!")
            let cell = UITableViewCell()
            return cell
        }
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        print(scrollView.contentOffset.y)
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier("StreamTableViewHeaderNavCell") as! StreamTableViewHeaderNavCell
        return cell
    }
}
