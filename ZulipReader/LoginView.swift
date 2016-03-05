////
////  LoginView.swift
////  ZulipReader
////
////  Created by Frank Tan on 3/5/16.
////  Copyright © 2016 Frank Tan. All rights reserved.
////
//
//import Foundation
//import Spring
//import UIKit
//
//protocol LoginViewDelegate: class {
//  func loginButtonDidTouch(username: String, password: String)
//}
//
//class LoginView: UIView {
//  
//  weak var delegate: LoginViewDelegate?
//  
//  @IBOutlet weak var dialogView: DesignableView!
//  @IBOutlet weak var usernameTextField: DesignableTextField!
//  @IBOutlet weak var passwordTextField: DesignableTextField!
//  
//  @IBAction func loginButtonDidTouch(sender: UIButton) {
//    usernameTextField.text = "frankctan@gmail.com"
//    passwordTextField.text = "recursion"
//    
//    guard let username = usernameTextField.text,
//      let password = passwordTextField.text
//      else {
//        dialogView.animation = "shake"
//        dialogView.animate()
//        return
//    }
//    self.delegate?.loginButtonDidTouch(username, password: password)
//  }
//}
//
//
