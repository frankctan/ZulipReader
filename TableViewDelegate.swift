//
//  TableViewDelegate.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/14/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import Foundation
import UIKit

class TableViewDelegate: NSObject, UITableViewDelegate {
    var messages = [[TableCell]]()
    var sender: StreamTableViewController?
    
    init(sender: StreamTableViewController?, messagesFromAPI: [[TableCell]]) {
        super.init()
        messages = messagesFromAPI
        if sender != nil {
        self.sender = sender!
        }
    }
    
    internal func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
      let headerType = messages[section][0].type
      
        if messages[section][0].type == "stream" {
            let cell = tableView.dequeueReusableCellWithIdentifier("StreamHeaderNavCell") as? StreamHeaderNavCell
            cell!.configureWithStream(messages[section][0])
            cell?.delegate = sender
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("StreamHeaderPrivateCell") as? StreamHeaderPrivateCell
            cell!.configureWithStream(messages[section][0])
            cell?.delegate = sender
            return cell
        }
    }
    
    internal func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 27.0
    }
}