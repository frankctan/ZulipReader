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
public var streamColorLookup = [String:String]()

class DataController {
  
  typealias Parameter = [String:AnyObject]
  let baseURL = "https://api.zulip.com/v1"
  
  enum Router: URLRequestConvertible {
    static let baseURL = "https://api.zulip.com/v1"
    static var basicAuth: String?
    
    case Login(username: String, password: String)
    case Register
    case GetSubscriptions
    case GetOldMessages(anchor: Int, before: Int, after: Int)
    case GetNarrowMessages(anchor: Int, before: Int, after: Int, narrow: String)
    //    case PostMessage(type: String, content: String, to: [String], subject: String?)
    
    var method: Alamofire.Method {
      switch self {
      case .Login, .Register:
        return .POST
      case .GetSubscriptions, .GetOldMessages, .GetNarrowMessages:
        return .GET
      }
    }
    
    var URLRequest: NSMutableURLRequest {
      let result: (path: String, parameters: [String: AnyObject]?) = {
        switch self {
          
        case .Login(let username, let password):
          let loginParams = ["username": username, "password": password]
          return ("/fetch_api_key", loginParams)
          
        case .Register:
          let registerParams = ["event_types:": ["message","pointer"]]
          return("/register", registerParams)
          
        case .GetSubscriptions:
          return("/users/me/subscriptions", nil)
          
        case .GetOldMessages(let anchor, let before, let after):
          let messageParams = ["anchor": anchor, "num_before": before, "num_after": after]
          return("/messages", messageParams)
          
        case .GetNarrowMessages(let anchor, let before, let after, let narrow):
          let messageParams = ["anchor": anchor, "num_before": before,
            "num_after": after, "narrow": narrow]
          
          return("/messages", (messageParams as! [String : AnyObject]))
        }
      }()
      
      let URL = NSURL(string: Router.baseURL)!
      let URLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(result.path))
      URLRequest.HTTPMethod = method.rawValue
      
      if let authHeader = Router.basicAuth {
        URLRequest.setValue(authHeader,forHTTPHeaderField: "Authorization")
      }
      
      let encoding = Alamofire.ParameterEncoding.URL
      print(encoding.encode(URLRequest, parameters: result.parameters).0)
      return encoding.encode(URLRequest, parameters: result.parameters).0
    }
    //      case .PostMessage(let type, let content, let recipients, let subject):
    //        if subject == nil {
    //          //PM
    //          return "/messages?type=\(type)&content=\(content)&to=\(recipients)"
    //        } else {
    //          //Stream
    //          return "/messages?type=\(type)&content=\(content)&to=\(recipients[0])&subject=\(subject!)"
    //        }

    //    }
  }
}