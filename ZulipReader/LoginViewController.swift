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
    let panGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: "viewDidPan:")
    view.addGestureRecognizer(panGestureRecognizer)
    usernameTextField.delegate = self
    passwordTextField.delegate = self
  }
  
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    super.init(nibName: "LoginView", bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  func viewDidPan(sender: AnyObject) {
    view.endEditing(true)
  }
  
  var loading = false
  @IBAction func loginButtonDidTouch(sender: UIButton) {
    if !loading {
      usernameTextField.text = "frankctan@gmail.com"
      passwordTextField.text = "recursion1"
      login()
      loading = true
    }
    
  }
  
  func login() {
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
      passwordTextField.text = ""
      dialogView.animation = "shake"
      dialogView.animate()
    }
  }
}

//MARK: UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    if textField.returnKeyType == UIReturnKeyType.Next {
      passwordTextField.becomeFirstResponder()
      return true
    }
    else if (textField.returnKeyType == UIReturnKeyType.Go) {
      self.login()
      view.endEditing(true)
      return true
    }
    return false
  }
}