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
    
    //TODO: create a new view for navigation!
    @IBOutlet weak var menuButton: UIBarButtonItem!

    @IBAction func homeButtonDidTouch(sender: AnyObject) {
        State = "stream"
        narrowTitle = "Stream"
        narrowParams = nil
        self.data.getStreamMessages(narrowParams)
        self.setTextInputbarHidden(true, animated: true)
    }
    
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
        super.init(coder: decoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        data.delegate = self
        
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        
        tableView.registerNib(UINib(nibName: "StreamHeaderNavCell", bundle: nil), forCellReuseIdentifier: "StreamHeaderNavCell")
        tableView.registerNib(UINib(nibName: "StreamHeaderPrivateCell", bundle: nil), forCellReuseIdentifier: "StreamHeaderPrivateCell")
        tableView.registerNib(UINib(nibName: "StreamCell", bundle: nil), forCellReuseIdentifier: "StreamCell")
        tableView.registerNib(UINib(nibName: "StreamExtendedCell", bundle: nil), forCellReuseIdentifier: "StreamExtendedCell")
        
        self.data.getStreamMessages(narrowParams)
        self.setTextInputbarHidden(true, animated: false)
        
        self.bounces = true
        self.shakeToClearEnabled = true
        self.keyboardPanningEnabled = true
        self.inverted = false
        self.textView.placeholder = "Message"
        self.textView.placeholderColor = UIColor.lightGrayColor()
        self.textInputbar.autoHideRightButton = true
        self.typingIndicatorView.canResignByTouch = true
        self.rightButton.setTitle("Send", forState: UIControlState.Normal)
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = "revealToggle:"
            //            revealViewController().rearViewRevealWidth = 150
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        data.getStreamMessages(narrowParams)
        
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
        guard !messages.isEmpty else {return}
        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: messages.last!.count-1, inSection: messages.count-1), atScrollPosition: .Bottom, animated: true)
    }
}

//MARK: StreamHeaderNavCellDelegate
extension StreamTableViewController: StreamHeaderNavCellDelegate {
    func narrowStream(stream: String) {
        narrowParams = [["stream","\(stream)"]]
        narrowTitle = stream
        State = "narrow"
        
        data.getStreamMessages(narrowParams)
        self.setTextInputbarHidden(true, animated: true)
    }
    
    func narrowSubject(stream: String, subject: String) {
        narrowParams = [["stream","\(stream)"],["topic","\(subject)"]]
        narrowTitle = subject
        narrowType = "stream"
        narrowSubject = subject
        narrowRecipient = [stream]
        State = "subject"
        data.getStreamMessages(narrowParams)
        self.setTextInputbarHidden(false, animated: true)
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
        data.getStreamMessages(narrowParams)
        self.setTextInputbarHidden(false, animated: true)
    }
}
