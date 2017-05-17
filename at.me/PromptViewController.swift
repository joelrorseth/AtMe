//
//  PromptViewController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-05-14.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

class PromptViewController: UIViewController {
    
    var promptDelegate: PromptViewDelegate?
    var changingAttribute: Constants.UserAttribute = .none
    var changingAttributeName: String = ""
    
    // ==========================================
    // ==========================================
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Important: Set delegate of the custom UIView
        let promptView = PromptView(frame: self.view.frame)
        
        promptView.promptDelegate = self
        promptView.changingAttribute = changingAttribute
        promptView.setLabel(label: changingAttributeName)
        
        self.view.addSubview(promptView)
    }
}

extension PromptViewController: PromptViewDelegate {
    
    // ==========================================
    // ==========================================
    func didCommitChange(value: String) {
        
        print("Commiting value: \(value) for key \(changingAttribute)")
        self.dismiss(animated: true, completion: nil)
    }
    
    // ==========================================
    // ==========================================
    func didCancelChange() {
        self.dismiss(animated: true, completion: nil)
    }
}
