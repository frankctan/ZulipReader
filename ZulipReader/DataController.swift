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
  var email = String()
}

//stream, narrow, subject
public var State:String = "stream"
public var userData = UserData()
public var streamColorLookup = [String:String]()

class DataController {
  
  typealias Parameter = [String:AnyObject]
  let baseURL = "https://api.zulip.com/v1"
  
  enum Router: URLRequestConvertible {
    static let baseURL = "https://api.zulip.com/v1"
    static var basicAuth: String?
    
    case Login(username: String, password: String)
    case Register
    //    case GetStreamMessages(anchor: String, before: Int, after: Int)
    //    case GetSubscriptions
    //    case GetNarrowMessages(anchor: String, before: Int, after: Int, narrowParams: [[String]])
    //    case PostMessage(type: String, content: String, to: [String], subject: String?)
    //    case longPoll(queueID: String, lastEventId: String)
    
    var method: Alamofire.Method {
      switch self {
      case .Login, .Register:
        return .POST
      }
    }
    
    var URLRequest: NSMutableURLRequest {
      let result: (path: String, parameters: [String: AnyObject]) = {
        switch self {
        case .Login(let username, let password):
          return ("/fetch_api_key", ["username": username, "password": password])
        case .Register:
          return("/register", ["event_types:": ["message","pointer"]])
        }
      }()
      
      let URL = NSURL(string: Router.baseURL)!
      let URLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(result.path))
      URLRequest.HTTPMethod = method.rawValue
      
      if let authHeader = Router.basicAuth {
        URLRequest.setValue(authHeader,forHTTPHeaderField: "Authorization")
      }
      
      let encoding = Alamofire.ParameterEncoding.URL
      return encoding.encode(URLRequest, parameters: result.parameters).0
    }
    //      switch self {
    //      case .Login(let username, let password):
    //        return "/fetch_api_key?username=\(username)&password=\(password)"
    //      case .Register:
    //        return "/register?event_types=[\"message\"]"
    //      case .GetStreamMessages(let anchor, let before, let after):
    //        return "/messages?anchor=\(anchor)&num_before=\(before)&num_after=\(after)"
    //      case .GetSubscriptions:
    //        return "/users/me/subscriptions"
    //      case .GetNarrowMessages(let anchor, let before, let after, let narrowParams):
    //        return "/messages?anchor=\(anchor)&num_before=\(before)&num_after=\(after)&narrow=\(narrowParams)"
    //      case .PostMessage(let type, let content, let recipients, let subject):
    //        if subject == nil {
    //          //PM
    //          return "/messages?type=\(type)&content=\(content)&to=\(recipients)"
    //        } else {
    //          //Stream
    //          return "/messages?type=\(type)&content=\(content)&to=\(recipients[0])&subject=\(subject!)"
    //        }
    //      case .longPoll(let queueID, let lastEventId):
    //        return "/events?queue_id=\(queueID)&last_event_id=\(lastEventId)"
    //      }
    //    }
  }
}