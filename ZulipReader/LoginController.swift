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
  
  func login(username: String, password: String) {
    fetchSecretKey(username, password: password).start {[weak self] result in
      guard let controller = self, let delegate = controller.delegate else {fatalError()}
      switch result {
      case .Success(let header):
        let authHeader = header.unbox
        controller.saveInKeychain(authHeader)
        controller.setRouterHeader(authHeader)
        delegate.didFinishFetch(true)
        
      case .Error(let error):
        print(error.unbox.description)
        delegate.didFinishFetch(false)
      }
    }
  }
  
  private func fetchSecretKey(username: String, password: String) -> Future<String, ZulipErrorDomain> {
    return createLoginRequest(username, password: password)
      .andThen(AlamofireRequest)
      .andThen(createHeaderSaveDefaults)
  }
  
  private func createLoginRequest(username: String, password: String) -> Future<URLRequestConvertible, ZulipErrorDomain> {
    let urlRequest = Router.Login(username: username, password: password)
    return Future<URLRequestConvertible, ZulipErrorDomain>(value: urlRequest)
  }
  
  private func createHeaderSaveDefaults(response: JSON) -> Future<String, ZulipErrorDomain> {
    let email = response["email"].stringValue
    saveDefaults(email)
    
    let secretKey = response["api_key"].stringValue
    let header = "Basic " + "\(email):\(secretKey)".dataUsingEncoding(NSUTF8StringEncoding)!.base64EncodedStringWithOptions([])
    return Future<String, ZulipErrorDomain>(value: header)
  }
  
  private func saveInKeychain(header: String) {
    do {
      try Locksmith.saveData(["Authorization": header], forUserAccount: "default")
      print("auth header saved header to keychain!")
    }
    catch {fatalError("keychain can't be set")}
  }
  
  private func saveDefaults(email: String) {
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setValue(email, forKey: "email")
  }
  
  private func setRouterHeader(header: String) {
    Router.basicAuth = header
    print("set Router Header!")
  }
}