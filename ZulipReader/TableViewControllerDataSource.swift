//
//  TableViewControllerDataSource.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/14/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import Foundation
import UIKit

class TableViewControllerDataSource: NSObject, UITableViewDataSource {
    var messages = [[Cell]]()
    var sender: UIViewController!
    
    init(send: UIViewController, messagesFromAPI: [[Cell]]) {
        super.init()
        messages = messagesFromAPI
        sender = send
    }
    internal func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return messages.count
    }
    
    internal func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages[section].count
    }
    
    internal func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let message = messages[indexPath.section][indexPath.row]
        var previousMessage = Cell()
        
        if indexPath.row > 0 {
            previousMessage = messages[indexPath.section][indexPath.row - 1]
        }
        
        if message.name != previousMessage.name {
            let cell = tableView.dequeueReusableCellWithIdentifier("StreamCell") as? StreamCell
            cell!.configureWithStream(message)
            return cell!
            
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("StreamExtendedCell") as? StreamExtendedCell
            cell!.configureWithStream(message)
            return cell!
        }
    }
}

