//heartbeat

//{
//    "result": "success",
//    "queue_id": "1449973412:316501",
//    "msg": "",
//    "events": [
//    {
//    "type": "heartbeat",
//    "id": 0
//    }
//    ]
//}

import SwiftyJSON
import Alamofire

enum Router: URLRequestConvertible {
  static let baseURL = "https://api.zulip.com/v1"
  
  case Login(username: String, password: String)
  //    case Register
  //    case GetStreamMessages(anchor: String, before: Int, after: Int)
  //    case GetSubscriptions
  //    case GetNarrowMessages(anchor: String, before: Int, after: Int, narrowParams: [[String]])
  //    case PostMessage(type: String, content: String, to: [String], subject: String?)
  //    case longPoll(queueID: String, lastEventId: String)
  
  var URLRequest: NSMutableURLRequest {
    let result: (path: String, parameters: [String: AnyObject]) = {
      switch self {
      case .Login(let username, let password):
        return ("/fetch_api_key", ["username": username, "password": password])
      }
    }()
    
    let URL = NSURL(string: Router.baseURL)!
    let URLRequest = NSURLRequest(URL: URL.URLByAppendingPathComponent(result.path))
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

Router.Login(username: "username", password: "haha123")

