//
//  StreamNarrowTableViewController.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/12/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit

class StreamNarrowTableViewController: BaseStreamTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        data.delegate = self
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier("StreamTableViewHeaderNavCell") as! StreamTableViewHeaderNavCell
        cell.configureWithStream(messages[section][0])
        return cell
    }

}

//MARK: StreamControllerDelegate
extension StreamNarrowTableViewController: StreamControllerDelegate {
    func streamController(messagesForTable: [[Cell]]) {
        messages = messagesForTable
        self.title = narrowTitle
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: messages.last!.count-1, inSection: messages.count-1), atScrollPosition: .Bottom, animated: true)
    }
}
