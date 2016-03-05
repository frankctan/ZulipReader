//
//  LoginViewController.swift
//  ZulipReader
//
//  Created by Frank Tan on 11/16/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import Spring

class LoginViewController: UIViewController {
  
  let data = LoginController()
  
  @IBOutlet weak var dialogView: DesignableView!
  @IBOutlet weak var usernameTextField: DesignableTextField!
  @IBOutlet weak var passwordTextField: DesignableTextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    data.delegate = self
  }
  
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    super.init(nibName: "LoginView", bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  @IBAction func loginButtonDidTouch(sender: UIButton) {
    usernameTextField.text = "frankctan@gmail.com"
    passwordTextField.text = "recursion"
    
    guard let username = usernameTextField.text,
      let password = passwordTextField.text
      else {
        dialogView.animation = "shake"
        dialogView.animate()
        return
    }
    data.login(username, password: password)
  }
}

//MARK: LoginControllerDelegate
extension LoginViewController: LoginControllerDelegate {
  func didFinishFetch(flag: Bool) {
    if flag {
      self.dismissViewControllerAnimated(true, completion: nil)
    }
    else {
      usernameTextField.text = ""
      passwordTextField.text = ""
      dialogView.animation = "shake"
      dialogView.animate()
    }
  }
}