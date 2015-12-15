//
//  StreamNarrowTableViewController.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/12/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import SlackTextViewController
import AMScrollingNavbar

class StreamNarrowTableViewController: SLKTextViewController {
    
    let data = StreamController()
    var messages = [[Cell]]()
    
    var narrowParams: [[String]]?
    var narrowTitle = "Stream"
    var narrowType = ""
    var narrowSubject:String? = ""
    var narrowRecipient = [String]()
    
    var dataSource: TableViewControllerDataSource!
    var tableDelegate: TableViewDelegate!

    required init!(coder decoder: NSCoder!) {
        super.init(tableViewStyle: UITableViewStyle.Plain)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.estimatedRowHeight = 60
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        
        tableView.registerNib(UINib(nibName: "StreamHeaderNavCell", bundle: nil), forCellReuseIdentifier: "StreamHeaderNavCell")
        tableView.registerNib(UINib(nibName: "StreamHeaderPrivateCell", bundle: nil), forCellReuseIdentifier: "StreamHeaderPrivateCell")
        tableView.registerNib(UINib(nibName: "StreamCell", bundle: nil), forCellReuseIdentifier: "StreamCell")
        tableView.registerNib(UINib(nibName: "StreamExtendedCell", bundle: nil), forCellReuseIdentifier: "StreamExtendedCell")
        
        self.data.delegate = self
        self.data.getStreamMessages(narrowParams)
        
        self.bounces = true
        self.shakeToClearEnabled = true
        self.keyboardPanningEnabled = true
        self.inverted = false
        self.textView.placeholder = "Message"
        self.textView.placeholderColor = UIColor.lightGrayColor()
        self.textInputbar.autoHideRightButton = true
        self.typingIndicatorView.canResignByTouch = true
        self.rightButton.setTitle("Send", forState: UIControlState.Normal)
    }
    
    //MARK: Tableview
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let navigationController = self.navigationController as? ScrollingNavigationController {
            navigationController.followScrollView(tableView, delay: 50.0)
        }
    }
    
    //MARK: SLKTextViewController
    override func didPressRightButton(sender: AnyObject!) {
        self.textView.refreshFirstResponder()
        let sendMessage = self.textView.text.copy() as! String
        super.didPressRightButton(sender)
        
        if narrowType == "private" {
            narrowSubject = nil
        }
        
        data.postMessage(narrowType, content: sendMessage, to: narrowRecipient, subject: narrowSubject)
    }
}

//MARK: StreamControllerDelegate
extension StreamNarrowTableViewController: StreamControllerDelegate {
    func streamController(messagesForTable: [[Cell]]) {
        messages = messagesForTable
        title = narrowTitle
        dataSource = TableViewControllerDataSource(send: self, messagesFromAPI: messages)
        tableDelegate = TableViewDelegate(send: nil, messagesFromAPI: messages)
        tableView.dataSource = dataSource
        tableView.delegate = tableDelegate
        tableView.reloadData()
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: messages.last!.count-1, inSection: messages.count-1), atScrollPosition: .Bottom, animated: true)
    }
}