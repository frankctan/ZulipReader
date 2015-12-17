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
    var streamSegue = ""
    
    override func viewDidLoad() {
        for (k,v) in Array(streamColorLookup).sort({$0.0 < $1.0}) {
            streamColor.append((k,v))
        }
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return streamColor.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("sideCell") as? SideMenuCell
        let cellLabels = streamColor[indexPath.row]
        cell!.configureWithStream(cellLabels.0, color: cellLabels.1)
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        streamSegue = streamColor[indexPath.row].0
//        performSegueWithIdentifier("menuNarrowSegue", sender: self)
        revealViewController().revealToggleAnimated(true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let nav = segue.destinationViewController as! ScrollingNavigationController
        let toView = nav.viewControllers[0] as! StreamTableViewController
        toView.narrowParams = [["stream","\(streamSegue)"]]
        toView.narrowTitle = streamSegue
        State = "narrow"
    }
}
