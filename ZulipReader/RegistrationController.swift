//
//  RegistrationController.swift
//  ZulipReader
//
//  Created by Frank Tan on 3/23/16.
//  Copyright © 2016 Frank Tan. All rights reserved.
//

import Foundation
import SwiftyJSON
import RealmSwift
import Alamofire

public struct Registration {
  var pointer = Int()
  var maxMessageID = Int()
  var queueID = String()
  var eventID = Int()
  var subscriptionJSON = [JSON]()
  
  init() {}
  
  init(_ pointer: Int, _ maxMessageID: Int, _ queueID: String, _ eventID: Int, _ subscription: [JSON]) {
    self.pointer = pointer
    self.maxMessageID = maxMessageID
    self.queueID = queueID
    self.eventID = eventID
    self.subscriptionJSON = subscription
  }
}

class RegistrationOperation: NetworkOperation {
  private var subscription = [String: String]()
  private var registration = Registration()

  override func main() {
    registrationPipeline()
      .start { result in
        switch result {
          
        case .Success(let boxedReg):
          let reg = boxedReg.unbox
          self.recordRegistration(reg)
          
        case .Error(let boxedError):
          let error = boxedError.unbox
          print("registration error: \(error)")
        }
        
        self.complete()
    }
  }
  
  //MARK: This is all the data we get from registration
  func getSubscriptionAndMaxID() -> ([String: String], Int) {
    return (self.subscription, self.registration.maxMessageID)
  }
  
  private func registrationPipeline() -> Future<Registration, ZulipErrorDomain> {
    return createRegistrationRequest()
      .andThen(AlamofireRequest)
      .andThen(getStreamAndAchor)
  }
  
  private func createRegistrationRequest() -> Future<URLRequestConvertible, ZulipErrorDomain> {
    let urlRequest = Router.Register
    return Future<URLRequestConvertible, ZulipErrorDomain>(value: urlRequest)
  }
  
  //while these fields are recorded, most are not used or referenced.
  private func getStreamAndAchor(response: JSON) -> Future<Registration, ZulipErrorDomain> {
    return Future<Registration, ZulipErrorDomain>(operation: { completion in
      let result: Result<Registration, ZulipErrorDomain>
      
      if let pointer = response["pointer"].int,
        let maxID = response["max_message_id"].int,
        let queueID = response["queue_id"].string,
        let eventID = response["last_event_id"].int,
        let subs = response["subscriptions"].array {
        
        let registration = Registration(pointer, maxID, queueID, eventID, subs)
        result = Result.Success(Box(registration))
      }
      else {
        result = Result.Error(Box(ZulipErrorDomain.ZulipRequestFailure(message: "unable to assign registration")))
      }
      completion(result)
    })
  }
  
  //writes subscription dictionary, realm persistence, sends subscription colors to sideMenuDelegate
  private func recordRegistration(registration: Registration) {
    print("registration saved")
    for sub in registration.subscriptionJSON {
      self.subscription[sub["name"].stringValue] = sub["color"].stringValue
    }
    self.registration = registration
  }
}