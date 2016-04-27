//: Playground - noun: a place where people can play

import UIKit
import SwiftyJSON


//TODO:

//clean up side menu ugliness
//redo the pods
//flash new messages once? - add all message id's to array if refresh/scroll up; if one of the messages shows up, flash visible new messages, clear out all messages from array

//make & hookup profile page - compromise with press user image for PM
//display starred messages - not doing this
//scroll logic of scrollDownIndicator
//auto dismissal of scrollDownIndicator






//preferably swipe left to PM / star? How to star? - this is just setting a flag...
//profile page
//test for network failure! - won't narrow with <30 messages if there's no network. Which is okay... just flash error on the title thing

//rows test always fails
//make notifications sexy - notification needs to go away by itself if user is already scrolled to the bottom / buttons are too small for pudgy fingers - they need to go away narrowed
//app icons
//refresh and load new messages at same time creates a problem. I think this is because realm updates db automatically so the new message is added unexpectedly
//Fix loading: StreamController -> StreamTableViewController
//muted messages/threads?
//get rid of unnecessary pods

var str = "Hello, playground"

let character: Character = Character("\u{1F565}")

var emojiRegex: NSRegularExpression {
  do {
    return try NSRegularExpression(pattern: "<img alt=\":([^:]+):\" class=\"emoji\" src=\"static/third/gemoji/images/emoji/[^.]+.png+\" title=\":[^:]+:\">", options: NSRegularExpressionOptions.CaseInsensitive)
  }
  catch let error as NSError {
    print("\n\n regex error: \(error) \n\n")
    return NSRegularExpression()
  }
}

let hashTable = [
":wrench:"                            : "\u{1F527}",
":octopus:"                           : "\u{1F419}"
]

let text = "<p><img alt=\":wrench:\" class=\"emoji\" src=\"static/third/gemoji/images/emoji/wrench.png\" title=\":wrench:\"> <br><img alt=\":octopus:\" class=\"emoji\" src=\"static/third/gemoji/images/emoji/octopus.png\" title=\":octopus:\"> </p>"

//let text = "<p><img alt=\":octopus:\" class=\"emoji\" src=\"static/third/gemoji/images/emoji/octopus.png\" title=\":octopus:\"> </p>"

//<img alt=\":wrench:\" class=\"emoji\" src=\"static/third/gemoji/images/emoji/octopus.png\" title=\":octopus:\"> "

//let textCopy = NSMutableString(string: text)
////var ahah = text
////
//let matches = emojiRegex.matchesInString(text, options: NSMatchingOptions.init(rawValue: 0), range: NSMakeRange(0, text.characters.count))
////
////matches.count
////
////let result = matches[0]
//let result2 = matches[0]
//
////emojiRegex.replaceMatchesInString(textCopy, options: NSMatchingOptions.init(rawValue: 0), range: NSMakeRange(0, textCopy.length), withTemplate: "$1")
//
//
//
//let emojiString = ":" + emojiRegex.replacementStringForResult(result2, inString: text, offset: 0, template: "$1") + ":"
//result2.range.location
//result2.range.length
//
//let range = result2.range
//
//
//let utfEmoji: String
//if let emoji = hashTable[emojiString] {
//  utfEmoji = emoji
//} else {
//  utfEmoji = emojiString
//}
//
//textCopy.replaceCharactersInRange(result2.range, withString: utfEmoji)

let matches = emojiRegex.matchesInString(text, options: NSMatchingOptions.init(rawValue: 0), range: NSMakeRange(0, text.characters.count))

let textCopy1 = NSMutableString(string: text)

var offset = 0
for match in matches {
  var range = match.range
  range.location += offset
  
  let emojiString = ":" + emojiRegex.replacementStringForResult(match, inString: textCopy1 as String, offset: offset, template: "$1") + ":"
  
  let utfEmoji: String
  if let emoji = hashTable[emojiString] {
    range.location
    range.length
    utfEmoji = emoji
  } else {
    textCopy1
    offset
    range.location
    utfEmoji = emojiString
  }
  
  textCopy1.replaceCharactersInRange(range, withString: utfEmoji)
  offset += NSMutableString(string: utfEmoji).length - range.length
}

let r = textCopy1 as String

r


let indexPaths = [NSIndexPath(forRow: 0, inSection: 0), NSIndexPath(forRow: 1, inSection: 0), NSIndexPath(forRow: 0, inSection: 1), NSIndexPath(forRow: 0, inSection: 2)]

let count = indexPaths.reduce(0, combine: {if $1.section == 0 {return $0 + 1}; return $0})

let count2 = indexPaths.filter {$0.row == 0}.count

count2



count

for indexPath in indexPaths {
  
}


let aStr: String? = "hello"

let bStr: String = "hello"

aStr == bStr

var stupidArray = [[String]]()
stupidArray.isEmpty

stupidArray.count


stupidArray.flatten().isEmpty




