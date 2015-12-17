//
//  SideMenuTableViewController.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/15/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import AMScrollingNavbar

class SideMenuTableViewController: UITableViewController {
    
    var streamColor = [(String, String)]()
    var titleCells = ["Private", "Starred", "@Mention"]
    var sectionTitles = ["GENERAL","STREAMS"]
    var selection = ""
    
    override func viewDidLoad() {
        for (k,v) in Array(streamColorLookup).sort({$0.0 < $1.0}) {
            streamColor.append((k,v))
        }
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return titleCells.count
        }
        return streamColor.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("sideCell") as? SideMenuCell
        
        if indexPath.section == 0 {
            cell!.configureWithStream(titleCells[indexPath.row], color: "FFFFFF")
        }
        if indexPath.section == 1 {
            let cellLabels = streamColor[indexPath.row]
            cell!.configureWithStream(cellLabels.0, color: cellLabels.1)
        }
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            selection = titleCells[indexPath.row]
        } else {
            selection = streamColor[indexPath.row].0
        }
        revealViewController().revealToggleAnimated(true)
        performSegueWithIdentifier("pushSegue", sender: self)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let nav = segue.destinationViewController as! ScrollingNavigationController
        let toController = nav.viewControllers[0] as! StreamTableViewController
        toController.narrowTitle = selection
        State = "narrow"
        switch selection {
        case "Private":
            toController.narrowParams = [["is","private"]]
        case "Starred":
            toController.narrowParams = [["is","starred"]]
        case "@Mention":
            toController.narrowParams = [["is","mentioned"]]
        default:
            toController.narrowParams = [["stream",selection]]
        }
    }
}
