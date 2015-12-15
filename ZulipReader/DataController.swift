//
//  DataController.swift
//  ZulipReader
//
//  Created by Frank Tan on 11/28/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON


public typealias Header = [String:String]

public struct UserData {
    var header = Header()
    var queueID = String()
    var pointer = String()
}

class DataController {
    
    typealias Parameter = [String:AnyObject]
    let baseURL = "https://api.zulip.com/v1"
    
    var userData = UserData()
    
    enum ResourcePath {
        case Login(username: String, password: String)
        case Register
        case GetStreamMessages(anchor: String, before: Int, after: Int)
        case GetSubscriptions
        case GetNarrowMessages(anchor: String, before: Int, after: Int, narrowParams: [[String]])
        case PostMessage(type: String, content: String, to: [String], subject: String?)
        
        var url: String {
            switch self {
            case .Login(let username, let password):
                return "/fetch_api_key?username=\(username)&password=\(password)"
            case .Register:
                return "/register?event_types=[\"message\",\"pointer\",\"realm_user\"]"
            case .GetStreamMessages(let anchor, let before, let after):
                return "/messages?anchor=\(anchor)&num_before=\(before)&num_after=\(after)"
            case .GetSubscriptions:
                return "/users/me/subscriptions"
            case .GetNarrowMessages(let anchor, let before, let after, let narrowParams):
                return "/messages?anchor=\(anchor)&num_before=\(before)&num_after=\(after)&narrow=\(narrowParams)"
            case .PostMessage(let type, let content, let recipients, let subject):
                if subject == nil {
                    //PM
                    return "/messages?type=\(type)&content=\(content)&to=\(recipients)"
                } else {
                    //Stream
                    return "/messages?type=\(type)&content=\(content)&to=\(recipients[0])&subject=\(subject!)"
                }
            }
        }
    }
    
    private func encodeURL(url: String) -> NSURL {
        let urlString = url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLFragmentAllowedCharacterSet())!
        let encodedURL = NSURL(string: urlString)!
        return encodedURL
    }
    
    func getURL(method: ResourcePath) -> NSURL  {
        let url = baseURL + method.url
        return encodeURL(url)
    }
}