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
    var messages = [JSON]()
}

class DataController {
    
    typealias Parameter = [String:AnyObject]
    let baseURL = "https://api.zulip.com/v1"
    
    var userData = UserData()
    
    enum ResourcePath {
        case Login(username: String, password: String)
        case Register
        case GetMessages(anchor: String, before: Int, after: Int)
        case GetSubscriptions
        
        var url: String {
            switch self {
            case .Login(let username, let password):
                return "/fetch_api_key?username=\(username)&password=\(password)"
            case .Register:
                return "/register?event_types=[\"message\",\"pointer\",\"realm_user\"]"
            case .GetMessages(let anchor, let before, let after):
                return "/messages?anchor=\(anchor)&num_before=\(before)&num_after=\(after)"
            case .GetSubscriptions:
                return "/users/me/subscriptions"
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