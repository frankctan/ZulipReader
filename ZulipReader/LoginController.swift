//
//  LoginController
//  ZulipReader
//
//  Created by Frank Tan on 11/18/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import Locksmith


protocol LoginControllerDelegate: class {
  func didFinishFetch(flag: Bool)
}

class LoginController : DataController {
  
  weak var delegate: LoginControllerDelegate?
  
//  func fetchKey(username: String, password: String) {
//    
//    Alamofire.request(Router.Login(username: username, password: password)).responseJSON {[weak self] res in
//      guard let controller = self,
//        let delegate = controller.delegate else {fatalError("unable to assign controller/delegate")}
//      let response = JSON(data: res.data!)
//      
//      guard response["result"].stringValue == "success" else {
//        print("fetchKey: \(response["msg"].stringValue)")
//        delegate.didFinishFetch(false)
//        return
//      }
//      
//      var header: [String: String] = [:]
//      header["username"] = response["email"].stringValue
//      header["password"] = response["api_key"].stringValue
//      
//      controller.setKeychainAndHeader(header)
//      delegate.didFinishFetch(true)
//    }
//  }
  
  private func saveInKeychain(header: String) {
    do {
      try Locksmith.saveData(["Authorization": Router.basicAuth!], forUserAccount: "default")
    }
    catch {fatalError("keychain can't be set")}
  }
  
  private func setRouterHeader(header: String) {
    Router.basicAuth = header
  }
  
//  private func createAuthorizationHeader(header: Header) -> String {
//    let head = "\(header["username"]!):\(header["password"]!)".dataUsingEncoding(NSUTF8StringEncoding)!.base64EncodedStringWithOptions([])
//    return "Basic \(head)"
//  }
  
  enum ZulipErrorDomain: ErrorType {
    case ZulipRequestFailure(message: String)
    case NetworkRequestFailure
    
    var description: String {
      switch self {
      case .ZulipRequestFailure(let message): return message
      case .NetworkRequestFailure: return "Network Request Failure"
      }
    }
  }
  
  func createLoginRequest(username: String, password: String) -> Future<URLRequestConvertible, ZulipErrorDomain> {
    let urlRequest = Router.Login(username: username, password: password)
    return Future<URLRequestConvertible, ZulipErrorDomain>(value: urlRequest)
  }
  
  func AlamofireRequest(urlRequest: URLRequestConvertible) -> Future<JSON, ZulipErrorDomain> {
    return Future<JSON, ZulipErrorDomain> { completion in
      Alamofire.request(urlRequest).response { _, _, res, err in
        let response = JSON(data: res!)
        let result: Result<JSON, ZulipErrorDomain>
        if err != nil {
          result = Result.Error(Box(ZulipErrorDomain.NetworkRequestFailure))
        }
        else {
          if response["result"].stringValue == "success" {
            result = Result.Success(Box(response))
          }
          else {
            print(response["msg"])
            result = Result.Error(Box(ZulipErrorDomain.ZulipRequestFailure(message: response["msg"].stringValue)))
          }
        }
        completion(result)
      }
    }
  }
  
  func createHeader(response: JSON) -> Future<String, ZulipErrorDomain> {
    let secretKey = response["api_key"].stringValue
    let email = response["email"].stringValue
    let header = "Basic \(email):\(secretKey)".dataUsingEncoding(NSUTF8StringEncoding)!.base64EncodedStringWithOptions([])
    
    return Future<String, ZulipErrorDomain>(value: header)
  }
  
  func fetchSecretKey(username: String, password: String) -> Future<String, ZulipErrorDomain> {
    return createLoginRequest(username, password: password)
      .andThen(AlamofireRequest)
      .andThen(createHeader)
  }
  
  func login(username: String, password: String) {
    fetchSecretKey(username, password: password).start { result in
      switch result {
      case .Success(let header):
        saveInKeychain(header.unbox)
      case .Error(let error):
        print(error.unbox.description)
      }
    }
  }
  
}