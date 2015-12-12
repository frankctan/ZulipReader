//
//  StreamNarrowTableViewController.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/12/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import AMScrollingNavbar

class StreamNarrowTableViewController: BaseStreamTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        data.delegate = self
    }
}

extension StreamNarrowTableViewController: StreamControllerDelegate {
    func streamController(messagesForTable: [[Cell]]) {
        messages = messagesForTable
        self.title = narrowTitle
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: messages.last!.count-1, inSection: messages.count-1), atScrollPosition: .Bottom, animated: true)
    }
}
