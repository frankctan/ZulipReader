//
//  TextMunger.swift
//  ZulipReader
//
//  Created by Frank Tan on 4/27/16.
//  Copyright © 2016 Frank Tan. All rights reserved.
//

import Foundation

class TextMunger {
  class func processMarkdown(text: String) -> NSAttributedString! {
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
  
  class func processEmoji(text: String) -> String {
    //translated most of this from the original Zulip ios project
    guard text.rangeOfString("static/third/gemoji/images/emoji") != nil else {return text}
    
    var emojiRegex: NSRegularExpression {
      do {
        return try NSRegularExpression(pattern: "<img alt=\":([^:]+):\" class=\"emoji\" src=\"static/third/gemoji/images/emoji/[^.]+.png+\" title=\":[^:]+:\">", options: NSRegularExpressionOptions.CaseInsensitive)
      }
      catch let error as NSError {
        print("\n\n regex error: \(error) \n\n")
        return NSRegularExpression()
      }
    }
    
    let matches = emojiRegex.matchesInString(text, options: NSMatchingOptions.init(rawValue: 0), range: NSMakeRange(0, text.characters.count))
    
    let textCopy = NSMutableString(string: text)
    
    var offset = 0
    for match in matches {
      var range = match.range
      range.location += offset
      
      let emojiString = ":" + emojiRegex.replacementStringForResult(match, inString: textCopy as String, offset: offset, template: "$1") + ":"
      
      let utfEmoji: String
      if let emoji = EMOJI_HASH[emojiString] {
        utfEmoji = emoji
      } else {
        utfEmoji = emojiString
      }
      
      //NSMutableString(utfEmoji).count = 2; String(emoji).character.count = 1
      textCopy.replaceCharactersInRange(range, withString: utfEmoji)
      offset += NSMutableString(string: utfEmoji).length - range.length
    }
    return textCopy as String
  }

}