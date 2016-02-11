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
  
  func fetchKey(username: String, password: String) {
    Alamofire.request(Router.Login(username: username, password: password)).responseJSON {[weak self] res in
      guard let controller = self,
        let delegate = controller.delegate else {fatalError("unable to assign controller/delegate")}
      let response = JSON(data: res.data!)
      print("fetchKey: \(response["msg"].stringValue)")
      
      guard response["result"].stringValue == "success" else {delegate.didFinishFetch(false); return}
      var header: [String: String] = [:]
      header["username"] = response["email"].stringValue
      header["password"] = response["api_key"].stringValue

      controller.setKeychainAndHeader(header)
      delegate.didFinishFetch(true)
    }
  }
  
  private func setKeychainAndHeader(header: Header) {
    Router.basicAuth = createAuthorizationHeader(header)
    do {
      try Locksmith.saveData(["Authorization": Router.basicAuth!], forUserAccount: "default")
    }
    catch {fatalError("keychain can't be set")}
  }
  
  private func createAuthorizationHeader(header: Header) -> String {
    let head = "\(header["username"]!):\(header["password"]!)".dataUsingEncoding(NSUTF8StringEncoding)!.base64EncodedStringWithOptions([])
    return "Basic \(head)"
  }
}