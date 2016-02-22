//
//  OldStreamTableViewController.swift
//  ZulipReader
//
//  Created by Frank Tan on 2/22/16.
//  Copyright © 2016 Frank Tan. All rights reserved.
//

import Foundation


//MARK: StreamHeaderNavCellDelegate
//extension StreamTableViewController: StreamHeaderNavCellDelegate {
//  func narrowStream(stream: String) {
//    narrowParams = [["stream","\(stream)"]]
//    narrowTitle = stream
//    State = "narrow"
//    longPollFlag = false
//    //    data.getStreamMessages(narrowParams)
//    self.setTextInputbarHidden(true, animated: true)
//  }
//  
//  func narrowSubject(stream: String, subject: String) {
//    narrowParams = [["stream","\(stream)"],["topic","\(subject)"]]
//    let encodedParams = [["stream","\(stream)"],["topic","\(subject)"]]
//    narrowTitle = subject
//    narrowType = "stream"
//    narrowSubject = subject
//    narrowRecipient = [stream]
//    State = "subject"
//    longPollFlag = false
//    //    data.getStreamMessages(encodedParams)
//    self.setTextInputbarHidden(false, animated: true)
//  }
//}
//
////MARK: StreamHeaderPrivateCellDelegate
//extension StreamTableViewController: StreamHeaderPrivateCellDelegate {
//  func narrowConversation(recipientID: String, cellTitle: String, emails: String, msgType: String, msgSubject: String, msgEmails: [String]) {
//    narrowType = msgType
//    narrowSubject = msgSubject
//    narrowRecipient = [emails]
//    narrowParams = [["pm_with","\(emails)"]]
//    narrowTitle = cellTitle
//    State = "subject"
//    longPollFlag = false
//    //    data.getStreamMessages(narrowParams)
//    self.setTextInputbarHidden(false, animated: true)
//  }
//}
//
//  //MARK: SLKTextViewController
//  override func didPressRightButton(sender: AnyObject!) {
//    self.textView.refreshFirstResponder()
//    let sendMessage = self.textView.text.copy() as! String
//    super.didPressRightButton(sender)
//
//    if narrowType == "private" {
//      narrowSubject = nil
//    }
//    if State == "subject" {
//      data.postMessage(narrowType, content: sendMessage, to: narrowRecipient, subject: narrowSubject)
//    }
//    data.getStreamMessages(narrowParams)
//  }
//}
//
////MARK: StreamControllerDelegate
//extension StreamTableViewController: StreamControllerDelegate {
//  func streamController(messagesForTable: [[Cell]]) {
//    messages = messagesForTable
//    self.title = narrowTitle
//    dataSource = TableViewControllerDataSource(send: self, messagesFromAPI: messages)
//    tableDelegate = TableViewDelegate(sender: self, messagesFromAPI: messages)
//    tableView.dataSource = dataSource
//    tableView.delegate = tableDelegate
//
//    self.tableView.reloadData()
//    guard !messages.isEmpty else {return}
//    self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: messages.last!.count-1, inSection: messages.count-1), atScrollPosition: .Bottom, animated: true)
//    if longPollFlag == false {
//      longPollFlag = true
////      data.callLongPoll()
//    }
//  }
//
//  func longPollDelegate(appendMessages: [[Cell]]) {
//    print("in long poll delegate")
//    for longPollMessages in appendMessages {
//      print(longPollMessages)
//      messages.append(longPollMessages)
//    }
//    print(messages.count)
//
//    longPollFlag = true
////    data.callLongPoll()
//
//    guard State == "stream" else {return}
//    dataSource = TableViewControllerDataSource(send: self, messagesFromAPI: messages)
//    tableDelegate = TableViewDelegate(sender: self, messagesFromAPI: messages)
//    tableView.dataSource = dataSource
//    tableView.delegate = tableDelegate
//    self.tableView.reloadData()
//
//  }
//}
//
