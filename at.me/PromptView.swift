//
//  PromptView.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-05-14.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

protocol PromptViewDelegate {
    func didCommitChange(value: String)
    func didCancelChange()
}

class PromptView: UIView {
    
    var promptDelegate: PromptViewDelegate?
    
    var changingAttribute: Constants.UserAttribute = .none
    var changingAttributeName: String = ""
    
    var textField: UITextField!
    var label: UILabel!
    
    // MARK: Initialization
    // ==========================================
    // ==========================================
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        
        
        // Dimmed view appears on top of self.view, but under popup view
        let dimmedView = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        dimmedView.alpha = 0.8  // change back
        dimmedView.backgroundColor = UIColor.black
        dimmedView.tag = 2000
        
        // Custom view to contain the popup             // 3000
        let popupView = UIView(frame: CGRect(x: 20, y: frame.height / 4, width: frame.width - 40, height: 220))
        popupView.layer.cornerRadius = 5
        popupView.layer.opacity = 1.0
        popupView.alpha = 1.0       // change back
        popupView.backgroundColor = UIColor.white
        popupView.tag = 1000
        
        // Label is added to the popup view
        label = UILabel(frame: CGRect(x: 0, y: 20, width: popupView.bounds.size.width, height: 20))
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.font = UIFont(name: "System", size: 14)
        label.text = "Enter a new \(changingAttributeName)"
        
        // Text field is added to the popup view
        textField = UITextField(frame: CGRect(x: 20, y: 50, width: popupView.bounds.size.width - 40, height: 34))
        textField.tag = 4000
        textField.borderStyle = .roundedRect
        textField.textColor = UIColor.darkGray
        textField.textColor = UIColor.black
        
        // Button is added to the popup view
        let button = UIButton(frame: CGRect(x: 30, y: popupView.bounds.size.height - 70, width: popupView.bounds.size.width - 60, height: 50))
        button.addTarget(self, action: #selector(changeCommitted), for: UIControlEvents.touchUpInside)
        button.backgroundColor = UIColor.darkGray
        button.contentHorizontalAlignment = .center
        button.setTitle("Save Changes", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "System", size: 16)
        button.layer.cornerRadius = 5
        
        // Add gesture recognizer to handle tapping outside of keyboard
        dimmedView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissPopup)))
        popupView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        
        // Add views to this view
        popupView.addSubview(label)
        popupView.addSubview(textField)
        popupView.addSubview(button)
        
        self.addSubview(dimmedView)
        self.addSubview(popupView)
    }

    // ==========================================
    // ==========================================
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    // MARKL: Protocol / PromptViewDelegate
    // ==========================================
    // ==========================================
    func changeCommitted() {
        dismissKeyboard()
        
        if let change = textField.text {
            promptDelegate?.didCommitChange(value: change)
        }
    }
    
    // ==========================================
    // ==========================================
    func setLabel(label: String) {
        self.label.text = "Enter a new " + label
    }
    
    // ==========================================
    // ==========================================
    func dismissPopup() {
        dismissKeyboard()
        promptDelegate?.didCancelChange()
    }
    
    // ==========================================
    // ==========================================
    func dismissKeyboard() {
        self.viewWithTag(4000)?.resignFirstResponder()
    }
}
