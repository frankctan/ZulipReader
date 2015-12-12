//
//  StreamTableViewController.swift
//  ZulipReader
//
//  Created by Frank Tan on 11/23/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import AMScrollingNavbar

class StreamTableViewController: BaseStreamTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        data.delegate = self
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier("StreamTableViewHeaderNavCell") as! StreamTableViewHeaderNavCell
        cell.configureWithStream(messages[section][0])
        cell.delegate = self
        return cell
    }
}

//MARK: StreamControllerDelegate
extension StreamTableViewController: StreamControllerDelegate {
    func streamController(messagesForTable: [[Cell]]) {
        messages = messagesForTable
        self.title = narrowTitle
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: messages.last!.count-1, inSection: messages.count-1), atScrollPosition: .Bottom, animated: true)
    }
}

//MARK: StreamTableViewHeaderNavCellDelegate
extension StreamTableViewController: StreamTableViewHeaderNavCellDelegate {
    func narrowStream(stream: String) {
        narrowParams = [["stream","\(stream)"]]
        narrowTitle = stream
        performSegueWithIdentifier("narrowStreamSegue", sender: self)
    }
    
    func narrowSubject(stream: String, subject: String) {
        narrowParams = [["stream","\(stream)"],["topic","\(subject)"]]
        narrowTitle = "\(stream) > \(subject)"
        performSegueWithIdentifier("narrowSubjectSegue", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var toView = BaseStreamTableViewController()
        if segue.identifier == "narrowStreamSegue" {
            toView = segue.destinationViewController as! StreamTableViewController
        } else {
            toView = segue.destinationViewController as! StreamNarrowTableViewController

        }
        toView.narrowParams = narrowParams
        toView.narrowTitle = narrowTitle
        toView.data.userData = data.userData
    }
}