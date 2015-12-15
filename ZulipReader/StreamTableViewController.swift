//
//  StreamTableViewController.swift
//  ZulipReader
//
//  Created by Frank Tan on 11/23/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import AMScrollingNavbar
import SlackTextViewController

class StreamTableViewController: SLKTextViewController {
    
    let data = StreamController()
    var messages = [[Cell]]()
    
    var narrowParams: [[String]]?
    var narrowTitle = "Stream"
    var narrowType = ""
    var narrowSubject:String?
    var narrowRecipient = [String]()

    var dataSource: TableViewControllerDataSource!
    var tableDelegate: TableViewDelegate!
    
    required init!(coder decoder: NSCoder!) {
//        super.init(tableViewStyle: UITableViewStyle.Plain)
        super.init(coder: decoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        data.delegate = self
        data.getStreamMessages(narrowParams)
        
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        
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
        
        if State == "stream" || State == "narrow" {
            self.setTextInputbarHidden(true, animated: true)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let navigationController = self.navigationController as? ScrollingNavigationController {
            navigationController.followScrollView(tableView, delay: 0.0)
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
        if State == "subject" {
            data.postMessage(narrowType, content: sendMessage, to: narrowRecipient, subject: narrowSubject)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let toView = segue.destinationViewController as! StreamTableViewController
        toView.narrowParams = narrowParams
        toView.narrowTitle = narrowTitle
        toView.narrowType = narrowType
        toView.narrowSubject = narrowSubject
        toView.narrowRecipient = narrowRecipient
        toView.data.userData = data.userData
    }
}

//MARK: StreamControllerDelegate
extension StreamTableViewController: StreamControllerDelegate {
    func streamController(messagesForTable: [[Cell]]) {
        messages = messagesForTable
        self.title = narrowTitle
        dataSource = TableViewControllerDataSource(send: self, messagesFromAPI: messages)
        tableDelegate = TableViewDelegate(sender: self, messagesFromAPI: messages)
        tableView.dataSource = dataSource
        tableView.delegate = tableDelegate

        self.tableView.reloadData()
        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: messages.last!.count-1, inSection: messages.count-1), atScrollPosition: .Bottom, animated: true)
    }
}

//MARK: StreamHeaderNavCellDelegate
extension StreamTableViewController: StreamHeaderNavCellDelegate {
    func narrowStream(stream: String) {
        narrowParams = [["stream","\(stream)"]]
        narrowTitle = title!
        State = "narrow"
        print(narrowParams)
        self.performSegueWithIdentifier("narrowStreamSegue", sender: self)
    }
    
    func narrowSubject(stream: String, subject: String) {
        narrowParams = [["stream","\(stream)"],["topic","\(subject)"]]
        narrowTitle = "\(stream) > \(subject)"
        narrowType = "stream"
        narrowSubject = subject
        narrowRecipient = [stream]
        State = "subject"
        self.performSegueWithIdentifier("narrowSubjectSegue", sender: self)
    }
}

//MARK: StreamHeaderPrivateCellDelegate
extension StreamTableViewController: StreamHeaderPrivateCellDelegate {
    func narrowConversation(recipientID: String, cellTitle: String, emails: String, msgType: String, msgSubject: String, msgEmails: [String]) {
        narrowType = msgType
        narrowSubject = msgSubject
        narrowRecipient = msgEmails
        narrowParams = [["pm_with","\(emails)"]]
        narrowTitle = cellTitle
        State = "subject"
        self.performSegueWithIdentifier("narrowSubjectSegue", sender: self)
    }
}
