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
  @IBOutlet weak var domainTextField: DesignableTextField!

  override func viewDidLoad() {
    super.viewDidLoad()
    data.delegate = self
    let panGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(LoginViewController.viewDidPan(_:)))
    view.addGestureRecognizer(panGestureRecognizer)
    usernameTextField.delegate = self
    passwordTextField.delegate = self
    domainTextField.delegate = self
  }
  
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    super.init(nibName: "LoginView", bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  func viewDidPan(sender: AnyObject) {
    self.reset()
  }
  
  var loading = false
  @IBAction func loginButtonDidTouch(sender: UIButton) {
    if !loading {
      login()
    }
  }
  
  func reset() {
    view.endEditing(true)
    let scrollView = self.view as! UIScrollView
    scrollView.setContentOffset(self.view.frame.origin, animated: true)
  }
  
  func login() {
    self.reset()
    
    guard let username = usernameTextField.text,
      let password = passwordTextField.text
      else {
        dialogView.animation = "shake"
        dialogView.animate()
        return
    }
    let domain = domainTextField.text
    
    loading = true

    data.login(username, password: password, domain: domain)
  }
}

//MARK: LoginControllerDelegate
extension LoginViewController: LoginControllerDelegate {
  func didFinishFetch(flag: Bool) {
    loading = false
    if flag {
      self.dismissViewControllerAnimated(true, completion: nil)
    }
    else {
      dialogView.animation = "shake"
      dialogView.animate()
    }
  }
}

//MARK: UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
  func textFieldDidBeginEditing(textField: UITextField) {
    let textFieldOrigin = textField.frame.origin.y + dialogView.frame.origin.y
    let viewBounds = self.view.bounds.height
    let offsetPoint = CGPoint(x: 0, y: textFieldOrigin - viewBounds/3)
    let scrollView = self.view as! UIScrollView
    scrollView.setContentOffset(offsetPoint, animated: true)
    
    if textField == domainTextField {
      domainTextField.text = "https://"
    }
  }
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    if textField.returnKeyType == UIReturnKeyType.Next {
      switch textField {
      case usernameTextField: passwordTextField.becomeFirstResponder()
      case passwordTextField: domainTextField.becomeFirstResponder()
      default: break
      }
      return true
    }
    else if (textField.returnKeyType == UIReturnKeyType.Go) {
      self.login()
      return true
    }
    
    return false
  }
}