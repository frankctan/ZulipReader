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

enum Router: URLRequestConvertible {
  static let baseURL = "https://api.zulip.com/v1"
  static var basicAuth: String?
  
  case Login(username: String, password: String)
  case Register
  case GetSubscriptions
  case GetMessages(anchor: Int, before: Int, after: Int, narrow: String?)
  case PostMessage(type: String, content: String, to: String, subject: String?)
  
  var method: Alamofire.Method {
    switch self {
    case .Login, .Register, .PostMessage:
      return .POST
    case .GetSubscriptions, .GetMessages:
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
        
      case .PostMessage(let type, let content, let recipient, let subject):
        let postParams: [String: AnyObject]
        if let messageSubject = subject {
          //Stream
          postParams = ["type": type, "content": content, "to": recipient, "subject": messageSubject]
        }
        else {
          //Private
          postParams = ["type": type, "content": content, "to": recipient]
        }
        return("/messages", postParams)
        
      case .GetSubscriptions:
        return("/users/me/subscriptions", nil)
        
      case .GetMessages(let anchor, let before, let after, let narrow):
        let messageParams: [String: AnyObject]
        if let narrowParams = narrow {
          messageParams = ["anchor": anchor, "num_before": before, "num_after": after, "narrow": narrowParams]
        }
        else {
          messageParams = ["anchor": anchor, "num_before": before, "num_after": after]
        }
        return("/messages", messageParams)
      }
    }()
    
    
    
    let URL = NSURL(string: Router.baseURL)!
    let URLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(result.path))
    URLRequest.HTTPMethod = method.rawValue
    
    if let authHeader = Router.basicAuth {
      URLRequest.setValue(authHeader,forHTTPHeaderField: "Authorization")
    }
    
    let encoding = Alamofire.ParameterEncoding.URLEncodedInURL
    let encodedURLRequest = encoding.encode(URLRequest, parameters: result.parameters).0
    print("router: \(result.parameters)")
    print("router: \(encodedURLRequest)")
    return encodedURLRequest
  }
}