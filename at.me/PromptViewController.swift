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
    
    // ==========================================
    // ==========================================
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Important: Set delegate of the custom UIView
        let promptView = PromptView(frame: self.view.frame)
        promptView.promptDelegate = self
        
        self.view.addSubview(promptView)
    }
}

extension PromptViewController: PromptViewDelegate {
    
    // ==========================================
    // ==========================================
    func didCommitChange() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // ==========================================
    // ==========================================
    func didCancelChange() {
        self.dismiss(animated: true, completion: nil)
    }
}
