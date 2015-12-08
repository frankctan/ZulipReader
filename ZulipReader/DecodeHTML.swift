//
//  DecodeHTML.swift
//  ZulipReader
//
//  Created by Frank Tan on 12/1/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import Foundation
import UIKit


extension String {
    var htmlToString:String {
        do {
            return try NSAttributedString(data: dataUsingEncoding(NSUTF8StringEncoding)!, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType,NSCharacterEncodingDocumentAttribute:NSUTF8StringEncoding], documentAttributes: nil).string
        } catch {
            return String()
        }
    }
    var htmlToNSAttributedString:NSAttributedString {
        do {
        return try NSAttributedString(data: dataUsingEncoding(NSUTF8StringEncoding)!, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType,NSCharacterEncodingDocumentAttribute:NSUTF8StringEncoding], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
}
