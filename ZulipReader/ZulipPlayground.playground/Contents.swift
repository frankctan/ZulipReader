//: Playground - noun: a place where people can play

import UIKit
import SwiftyJSON


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





