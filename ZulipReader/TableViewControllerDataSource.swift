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
  var messages = [[TableCell]]()
  var sender: UIViewController!
  
  internal func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return messages.count
  }
  
  internal func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return messages[section].count
  }
  
  internal func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let message = messages[indexPath.section][indexPath.row]
    let cell: UITableViewCell
    
    switch message.cellType {
    case .StreamCell:
      cell = tableView.dequeueReusableCellWithIdentifier(message.cellType.string) as! StreamCell
    case .ExtendedCell:
      cell = tableView.dequeueReusableCellWithIdentifier(message.cellType.string) as! StreamExtendedCell
    }
    
    cell.configure(message)
    return cell
    
  }
}

