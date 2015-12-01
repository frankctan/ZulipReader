//
//  LoginViewController.swift
//  ZulipReader
//
//  Created by Frank Tan on 11/16/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import Spring

class LoginViewController: UIViewController, LoginControllerDelegate {
    
    let data = LoginController()
    
    @IBOutlet weak var dialogView: DesignableView!
    @IBOutlet weak var usernameTextField: DesignableTextField!
    @IBOutlet weak var passwordTextField: DesignableTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        data.delegate = self
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
            print(msg)
            dialogView.animation = "shake"
            dialogView.animate()

        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let nav = segue.destinationViewController as! UINavigationController
        let toView = nav.topViewController as! StreamTableViewController
        toView.data.userData = data.userData
    }
}

