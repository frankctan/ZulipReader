//
//  MessageArrayToTableCellArray.swift
//  ZulipReader
//
//  Created by Frank Tan on 3/22/16.
//  Copyright © 2016 Frank Tan. All rights reserved.
//

import Foundation
import RealmSwift

protocol MessageArrayToTableCellArrayDelegate: class {
  func messageToTableCellArrayDidFinish(tableCells: [[TableCell]], deletedSections: NSRange, insertedSections: NSRange, insertedRows: [NSIndexPath], userAction: UserAction)
  
  func realmNeedsMoreMessages()
}

class MessageArrayToTableCellArray: NSOperation {
  
  weak var delegate: MessageArrayToTableCellArrayDelegate?
  private let action: Action
  private var oldTableCells = [[TableCell]]()
  private let isLast: Bool
  
  //NSOperation Output
  private var tableCells = [[TableCell]]()
  private var deletedSections = NSRange()
  private var insertedSections = NSRange()
  private var insertedRows = [NSIndexPath]()
  
  init(action: Action, oldTableCells: [[TableCell]], isLast: Bool) {
    self.action = action
    self.oldTableCells = oldTableCells
    self.isLast = isLast
  }
  
  override func main() {
    let realm: Realm
    do {
      realm = try Realm()
    } catch {fatalError()}
    
    let narrowPredicate = action.narrow.predicate()
    let userAction = action.userAction
    //returns predicate based on current table max and narrow min
    let idPredicate = minMaxPredicate()
    
    //realm messages returns all the messages
    let realmMessages = NSArray(array: realm.objects(Message)
      .filter(idPredicate)
      .sorted("id", ascending: true)
      .map {$0})
    
    
    //This second layer of filtering is necessary because Realm can't recognize "ALL"
    //This approach is inefficient because we're not taking advantage of realm's lazy initiation...
    let allFilteredMessages = realmMessages.filteredArrayUsingPredicate(narrowPredicate) as! [Message]
    
    let flatOldTableCells = oldTableCells.flatten()
    //messageThreshold triggers a network call if thres isn't met
    //Focus case included for clarity
    var messageThreshold = 30
    switch userAction {
    case .Focus:
      messageThreshold = 30
    case .ScrollUp:
      messageThreshold += flatOldTableCells.count
    case .Refresh:
      let lastOldTableCellId = flatOldTableCells.last!.id
      messageThreshold = flatOldTableCells.count +
        allFilteredMessages.reduce(0, combine: {total, msg in
        if msg.id > lastOldTableCellId {
          return total + 1
        }
        return total
      })
    }
    
    if self.cancelled {
      return
    }
    
    if userAction == .Refresh && messageThreshold == flatOldTableCells.count {
      print("TCOp: Refresh - no new msgs in current narrow")
      //TODO: call delegate to add badge to home button
      return
    }
    
    if isLast == false && allFilteredMessages.count < messageThreshold {
      self.delegate?.realmNeedsMoreMessages()
      print("TCOp: MessageArrayToTableCellArray: less than \(messageThreshold) msgs")
      return
    }
    
    
    
    print("TCOp: computing realm messages")
    let allReversedMessages = Array(allFilteredMessages.reverse())
    var _tableCellMessages = [Message]()
    for counter in 0 ..< min(messageThreshold, allFilteredMessages.count) {
      _tableCellMessages.append(allReversedMessages[counter])
    }
    
    let tableCellMessages = Array(_tableCellMessages.reverse())
    
    if self.cancelled {
      return
    }
    
    let realmTableCells = self.messageToTableCell(tableCellMessages)
    
    if self.cancelled {
      return
    }

    self.tableCells = realmTableCells
    (self.deletedSections, self.insertedSections, self.insertedRows) = self.findTableUpdates(realmTableCells, action: userAction)
    
    
    //we're checking
    let calculatedSections = oldTableCells.count - self.deletedSections.length + self.insertedSections.length
    if calculatedSections != realmTableCells.count {
      print("sections error! - recalculating")
      (self.deletedSections, self.insertedSections, self.insertedRows) = self.findTableUpdates(realmTableCells, action: userAction)
    }
      
    else {
      for sectionIndex in 0 ..< realmTableCells.count {
        if sectionIndex < oldTableCells.count {
          let rowCountInSection = insertedRows.filter {$0.section == sectionIndex}.count
          if oldTableCells[sectionIndex].count + rowCountInSection != realmTableCells[sectionIndex].count {
            print("rows error! - recalculating")
            (self.deletedSections, self.insertedSections, self.insertedRows) = self.findTableUpdates(realmTableCells, action: userAction)
            break
          }
        }
      }
    }
    
    if self.cancelled {
      return
    }
    
    self.delegate?.messageToTableCellArrayDidFinish(tableCells, deletedSections: deletedSections, insertedSections: insertedSections, insertedRows: insertedRows, userAction: self.action.userAction)
  }
  
  func minMaxPredicate() -> NSPredicate {
    //min & max message indices are stored in NSUserDefaults
    let defaults = NSUserDefaults.standardUserDefaults()
    
    //network delegate called if id's are 0
    let homeMinId = defaults.integerForKey("homeMin")
    let homeMaxId = defaults.integerForKey("homeMax")
    
    var minId = homeMinId
    let maxId = homeMaxId
    
    if let narrowString = self.action.narrow.narrowString {
      minId = defaults.integerForKey(narrowString)
    }
    
    //make predicates
    let minIdPredicate = NSPredicate(format: "id >= %d", minId)
    let maxIdPredicate = NSPredicate(format: "id <= %d", maxId)
    let andPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [minIdPredicate, maxIdPredicate])
    print("TCOp: MessageArrayToTableCell Array idPredicate: \(andPredicate)")
    return andPredicate
  }
  
  private func findTableUpdates(realmTableCells: [[TableCell]], action: UserAction) -> (deletedSections: NSRange, insertedSections: NSRange, insertedRows: [NSIndexPath]) {
    
    //find the differences between oldTableCells and the new messages to be loaded
    var deletedSections = NSRange()
    var insertedSections = NSRange()
    var insertedRows = [NSIndexPath]()
    
    let flatRealmTableCells = realmTableCells.flatMap {$0}
    
    switch action {
    case .Focus:
      deletedSections = NSMakeRange(0, oldTableCells.count)
      insertedSections = NSMakeRange(0, realmTableCells.count)
      insertedRows = flatRealmTableCells.map {NSIndexPath(forRow: $0.row, inSection: $0.section)}
      
    case .ScrollUp:
      let oldTableCellsId = self.oldTableCells.flatMap {$0}.map {$0.id}
      insertedSections = NSMakeRange(0, realmTableCells.count - oldTableCells.count)
      for section in 0...insertedSections.length {
        for tableCell in realmTableCells[section] {
          if !oldTableCellsId.contains(tableCell.id) {
            insertedRows.append(NSIndexPath(forRow: tableCell.row, inSection: section))
          }
        }
      }
      
    case .Refresh:
      let flatOldTableCells = self.oldTableCells.flatMap {$0}
      let oldTableCellsId = flatOldTableCells.map {$0.id}
      guard let lastOldTableCell = flatOldTableCells.last else {break}
      
      let rangeLength = realmTableCells.count - oldTableCells.count
      
      insertedSections = NSMakeRange(lastOldTableCell.section + 1, rangeLength)
      
      let firstSection = lastOldTableCell.section
      let lastSection = firstSection + rangeLength
      
      for section in firstSection...lastSection {
        for tableCell in realmTableCells[section] {
          if !oldTableCellsId.contains(tableCell.id) {
            insertedRows.append(NSIndexPath(forRow: tableCell.row, inSection: section))
          }
        }
      }
    }
    
    //TODO: Add a check to verify that deleted/inserted Sections and insertedRows matches the number of messages that should appear. If not, action = .Focus to force a complete recalculation
    
    print("TCOp: action: \(action)")
    print("TCOp: deletedSections: \(deletedSections)")
    print("TCOp: insertedSections: \(insertedSections)")
    print("TCOp: insertedRows: \(insertedRows.count)")
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
//      let emojiMessageContent = processEmoji(messageContent)
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
    //8bit enoding caused text to be interpreted incorrectly, using 16bit
    let htmlData = text.dataUsingEncoding(NSUTF16StringEncoding, allowLossyConversion: false)
    
    do {
      htmlString = try NSAttributedString(data: htmlData!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
    } catch _ {
      htmlString = nil
    }
    return htmlString
  }
  
//  private func processEmoji(text: String) -> String {
//    //translated most of this from the original Zulip ios project
//    guard text.rangeOfString("static/third/gemoji/images/emoji") != nil else {return text}
//    
//    var emojiRegex: NSRegularExpression {
//      do {
//        return try NSRegularExpression(pattern: "<img alt=\":([^:]+):\" class=\"emoji\" src=\"static/third/gemoji/images/emoji/[^.]+.png+\" title=\":[^:]+:\">", options: NSRegularExpressionOptions.CaseInsensitive)
//      }
//      catch let error as NSError {
//        print("\n\n regex error: \(error) \n\n")
//        return NSRegularExpression()
//      }
//    }
//
//    let matches = emojiRegex.matchesInString(text, options: NSMatchingOptions.init(rawValue: 0), range: NSMakeRange(0, text.characters.count))
//    
//    let textCopy = NSMutableString(string: text)
//    
//    var offset = 0
//    for match in matches {
//      var range = match.range
//      range.location += offset
//      
//      let emojiString = ":" + emojiRegex.replacementStringForResult(match, inString: textCopy as String, offset: offset, template: "$1") + ":"
//      
//      let utfEmoji: String
//      if let emoji = EMOJI_HASH[emojiString] {
//        utfEmoji = emoji
//      } else {
//        utfEmoji = emojiString
//      }
//      
//      //NSMutableString(utfEmoji).count = 2; String(emoji).character.count = 1
//      textCopy.replaceCharactersInRange(range, withString: utfEmoji)
//      offset += NSMutableString(string: utfEmoji).length - range.length
//    }
//    return textCopy as String
//  }
  
}