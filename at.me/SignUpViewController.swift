//
//  SignUpViewController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-03-10.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // ==========================================
    // ==========================================
    @IBAction func didTapCreateAccount(_ sender: Any) {
    }
    
    // ==========================================
    // ==========================================
    @IBAction func transitionToSignIn(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
}
