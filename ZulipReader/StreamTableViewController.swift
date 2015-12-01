//
//  StreamTableViewController.swift
//  ZulipReader
//
//  Created by Frank Tan on 11/23/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import SwiftyJSON

class StreamTableViewController: UITableViewController, StreamControllerDelegate {

    let data = StreamController()
    var messages = [JSON]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        data.delegate = self
        data.getMessages()
    }
    
    func streamController(allMessages: [JSON]) {
        messages = allMessages
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("StreamTableViewCell") as! StreamTableViewCell
        cell.configureWithStream(messages[indexPath.row])
        return cell
    }
}