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

protocol LoginControllerDelegate: class {
    func loginController(msg: String)
}

class LoginController : DataController {
    
    weak var delegate: LoginControllerDelegate?
    
    
    func login(username: String, password: String) {
        let loginURL = getURL(.Login(username: username, password: password))
        
        Alamofire.request(.POST, loginURL).responseJSON {[weak self] res in
            guard let response = self?.evalJSONResult(res) else {return}
            guard response.flag == true else {return}
            
            var loginInfo = ["username":"", "password":""]
            loginInfo["username"] = username
            loginInfo["password"] = response.data["api_key"].stringValue
            userData.email = username

            guard let controller = self else {return}
            userData.header = controller.createAuthorizationHeader(loginInfo)
            controller.registerQueueIdPointer()
        }
    }
    
    func registerQueueIdPointer() {
        let regURL = getURL(.Register)
        Alamofire.request(.POST, regURL, headers: userData.header).responseJSON {[weak self] res in
            guard let response = self?.evalJSONResult(res) else {return}
            guard response.flag == true else {return}

            guard let controller = self else {return}
            userData.queueID = response.data["queue_id"].stringValue
            userData.pointer = response.data["max_message_id"].stringValue
            controller.delegate?.loginController(response.data["msg"].stringValue)
        }
    }
    
    func createAuthorizationHeader(credentials: Header) -> Header {
        let credentialData = "\(credentials["username"]!):\(credentials["password"]!)".dataUsingEncoding(NSUTF8StringEncoding)!.base64EncodedStringWithOptions([])
        return ["Authorization": "Basic \(credentialData)"]
    }
    
    func evalJSONResult(input: (Response<AnyObject, NSError>)) -> (flag: Bool, data: JSON) {
        let responseData = JSON(data: input.data!)
        guard responseData["result"].stringValue == "success" else {
            delegate?.loginController(responseData["msg"].stringValue)
            return (false, responseData)
        }
        return (true, responseData)
    }
    
    func isLoggedIn() -> Bool {
        if userData.queueID == "" {
            return false
        } else {
        return true
        }
    }
}