//
//  LoginViewController.swift
//  ZulipReader
//
//  Created by Frank Tan on 11/16/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import Spring
import AMScrollingNavbar

class LoginViewController: UIViewController, LoginControllerDelegate {
  
  let data = LoginController()
  
  @IBOutlet weak var dialogView: DesignableView!
  @IBOutlet weak var usernameTextField: DesignableTextField!
  @IBOutlet weak var passwordTextField: DesignableTextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    data.delegate = self
//    NSUserDefaults.standardUserDefaults().setObject("12345", forKey: "pointer")
//    let defaults = NSUserDefaults.standardUserDefaults()
//    print("default header: \(defaults.objectForKey("pointer"))")
//    if let header = defaults.objectForKey("header"),
//      let queueID = defaults.stringForKey("queueID"),
//      let pointer = defaults.stringForKey("pointer"),
//      let email = defaults.stringForKey("email") {
//        userData.header = header as! Header
//        userData.queueID = queueID
//        userData.pointer = pointer
//        userData.email = email
//        print("userStruct reassigned!")
//        performSegueWithIdentifier("loginSegue",sender: self)
//    }
  }
  
  override func viewDidAppear(animated: Bool) {
    let defaults = NSUserDefaults.standardUserDefaults()
    if let header = defaults.objectForKey("header"),
      let queueID = defaults.stringForKey("queueID"),
      let pointer = defaults.stringForKey("pointer"),
      let email = defaults.stringForKey("email") {
        userData.header = header as! Header
        userData.queueID = queueID
        userData.pointer = pointer
        userData.email = email
        print("userStruct reassigned!")
        performSegueWithIdentifier("loginSegue",sender: self)
    }

  }
  
  @IBAction func loginButtonDidTouch(sender: UIButton) {
    usernameTextField.text = "frankctan@gmail.com"
    passwordTextField.text = "recursion"
    data.login(usernameTextField.text!, password: passwordTextField.text!)
  }
  
  
  func loginController(msg: String) {
    usernameTextField.text = ""
    passwordTextField.text = ""
    if data.isLoggedIn() {
      performSegueWithIdentifier("loginSegue", sender: self)
    } else {
      dialogView.animation = "shake"
      dialogView.animate()
      
    }
  }
}