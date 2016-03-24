//
//  MessageArrayToTableCellArray.swift
//  ZulipReader
//
//  Created by Frank Tan on 3/22/16.
//  Copyright © 2016 Frank Tan. All rights reserved.
//

import Foundation
import RealmSwift

class MessageArrayToTableCellArray: NSOperation {
  
  private var newMessages: [Message]
  private let action: Action
  private let oldTableCells: [[TableCell]]
  
  //output
  private var tableCells = [[TableCell]()]
  private var deletedSections = NSRange()
  private var insertedSections = NSRange()
  private var insertedRows = [NSIndexPath]()
  
  init(action: Action, newMessages: [Message], oldTableCells: [[TableCell]]) {
    self.action = action
    self.newMessages = newMessages
    self.oldTableCells = oldTableCells
  }
  
  override func main() {
    print("in main")
    let realm: Realm
    do {
      realm = try Realm()
    } catch {fatalError()}
    print("initialized realm")
    
    let realmMessages = NSArray(array: realm.objects(Message).sorted("id", ascending: true).map {$0})
    let allFilteredMessages = realmMessages.filteredArrayUsingPredicate(action.narrow.predicate()) as! [Message]

    let realmTableCells = self.messageToTableCell(allFilteredMessages)
    if newMessages.isEmpty {
      self.newMessages = allFilteredMessages
    }
    (self.deletedSections, self.insertedSections, self.insertedRows) = self.findTableUpdates(realmTableCells, newMessages: newMessages, action: action.userAction)
    self.tableCells = realmTableCells
  }
  
  func getTableCells() -> ([[TableCell]], NSRange, NSRange, [NSIndexPath]) {
    return (self.tableCells, self.deletedSections, self.insertedSections, self.insertedRows)
  }
  
  private func findTableUpdates(realmTableCells: [[TableCell]], newMessages: [Message], action: UserAction) -> (deletedSections: NSRange, insertedSections: NSRange, insertedRows: [NSIndexPath]) {
    
    print("allMessages Section Count: \(realmTableCells.count)")
    
    let newMessageTableCells = self.messageToTableCell(newMessages)
    
    print("newMessages Section Count: \(newMessageTableCells.count)")
    let flatNewMessageTableCells = newMessageTableCells.flatMap {$0}
    let flatOldTableCells = oldTableCells.flatMap {$0}
    
    var deletedSections = NSRange()
    var insertedSections = NSRange()
    var insertedRows = [NSIndexPath]()
    
    print("flatOld#: \(flatOldTableCells.count) + flatNew#: \(flatNewMessageTableCells.count) = newMessage#: \(realmTableCells.reduce(0, combine: {$0 + $1.count}))")
    
    switch action {
    case .Focus:
      deletedSections = NSMakeRange(0, oldTableCells.count)
      insertedSections = NSMakeRange(0, realmTableCells.count)
//      insertedRows = realmTableCells.flatMap {$0}.map {NSIndexPath(forRow: $0.row, inSection: $0.section)}
      
    case .ScrollUp:
      insertedSections = NSMakeRange(0, realmTableCells.count - oldTableCells.count)
      for section in insertedSections.location...(insertedSections.location+insertedSections.length) {
        for tableCells in realmTableCells[section] {
          
        }
      }
//      insertedRows = flatNewMessageTableCells.map {NSIndexPath(forRow: $0.row, inSection: $0.section)}
      
    case .Refresh:
      let lastOldTableCell = flatOldTableCells.last!
      let rangeLength = realmTableCells.count - oldTableCells.count
        insertedSections = NSMakeRange(lastOldTableCell.section + 1, rangeLength)
      }
//      let newMessageCount = newMessages.count
//      let flatrealmTableCells = realmTableCells.flatMap {$0}
//      for index in (flatrealmTableCells.count - newMessageCount)..<flatrealmTableCells.count {
//        insertedRows.append(NSIndexPath(forRow: flatrealmTableCells[index].row, inSection: flatrealmTableCells[index].section))
//      }
    }
    
    return (deletedSections, insertedSections, insertedRows)
  }

  private func messageToTableCell(messages: [Message]) -> [[TableCell]] {
    var previous = TableCell()
    var result = [[TableCell]()]
    var sectionCounter = 0
    var rowCounter = 0
    
    for message in messages {
      var cell = TableCell(message)
      let messageContent = message.content
      let attributedContent = processMarkdown(messageContent)
      cell.attributedContent = attributedContent
      
      if previous.isEmpty {
        result[sectionCounter].append(cell)
        previous = cell
        continue
      }
      
      if previous.display_recipient != cell.display_recipient ||
        previous.subject != cell.subject ||
        previous.type != cell.type {
        
        sectionCounter += 1
        rowCounter = 0
        cell.section = sectionCounter
        cell.row = rowCounter
        result.append([cell])
      }
      else {
        if previous.sender_full_name == cell.sender_full_name {
          cell.cellType = CellTypes.ExtendedCell
        }
        
        rowCounter += 1
        cell.section = sectionCounter
        cell.row = rowCounter
        result[sectionCounter].append(cell)
      }
      previous = cell
    }
    
    return result
  }
  
  private func processMarkdown(text: String) -> NSAttributedString! {
    //Swift adds an extra "\n" to paragraph tags so we replace with span.
    var text = text.stringByReplacingOccurrencesOfString("<p>", withString: "<span>")
    text = text.stringByReplacingOccurrencesOfString("</p>", withString: "</span>")
    //CSS from the original zulip-ios project
    let style = ["<style>",
      "body{font-family:\"SourceSansPro-Regular\";font-size:17px;line-height:17px;}",
      "span.user-mention {padding: 2px 4px; background-color: #F2F2F2; border: 1px solid #e1e1e8;}",
      ".hll{background-color:#ffc}{background:#f8f8f8} .c{color:#408080;font-style:italic} .err{border:1px solid #f00} .k{color:#008000;font-weight:bold} .o{color:#666} .cm{color:#408080;font-style:italic} .cp{color:#bc7a00} .c1{color:#408080;font-style:italic} .cs{color:#408080;font-style:italic} .gd{color:#a00000} .ge{font-style:italic} .gr{color:#f00} .gh{color:#000080;font-weight:bold} .gi{color:#00a000} .go{color:#808080} .gp{color:#000080;font-weight:bold} .gs{font-weight:bold} .gu{color:#800080;font-weight:bold} .gt{color:#0040d0} .kc{color:#008000;font-weight:bold} .kd{color:#008000;font-weight:bold} .kn{color:#008000;font-weight:bold} span.kp{color:#008000} .kr{color:#008000;font-weight:bold} .kt{color:#b00040} .m{color:#666} .s{color:#ba2121} .na{color:#7d9029} .nb{color:#008000} .nc{color:#00f;font-weight:bold} .no{color:#800} .nd{color:#a2f} .ni{color:#999;font-weight:bold} .ne{color:#d2413a;font-weight:bold} .nf{color:#00f} .nl{color:#a0a000} .nn{color:#00f;font-weight:bold} .nt{color:#008000;font-weight:bold} .nv{color:#19177c} .ow{color:#a2f;font-weight:bold} .w{color:#bbb} .mf{color:#666} .mh{color:#666} .mi{color:#666} .mo{color:#666} .sb{color:#ba2121} .sc{color:#ba2121} .sd{color:#ba2121;font-style:italic} .s2{color:#ba2121} .se{color:#b62;font-weight:bold} .sh{color:#ba2121} .si{color:#b68;font-weight:bold} .sx{color:#008000} .sr{color:#b68} .s1{color:#ba2121} .ss{color:#19177c} .bp{color:#008000} .vc{color:#19177c} .vg{color:#19177c} .vi{color:#19177c} .il{color:#666}",
      "blockquote {border-left-color: #dddddd;border-left-style: solid;border-left: 5px;}",
      "a {color:0088cc}",
      "code {padding: 2px 4px;color: #d14;background-color: #F5F5F5;border: 1px solid #e1e1e8;}",
      "img {max-height: 200px}",
      "</style>"].reduce("",combine: +)
    text += style
    let htmlString: NSAttributedString?
    //8 bit enoding caused text to be interpreted incorrectly
    let htmlData = text.dataUsingEncoding(NSUTF16StringEncoding, allowLossyConversion: false)
    
    do {
      htmlString = try NSAttributedString(data: htmlData!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
    } catch _ {
      htmlString = nil
    }
    return htmlString
  }

}