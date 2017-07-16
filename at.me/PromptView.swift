//
//  PromptView.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-05-14.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

// Protocol defines methods that will be called in response to certain actions within PromptView
protocol PromptViewDelegate {
    func didCommitChange(value: String)
    func didCancelChange()
}

class PromptView: UIView {
    
    var promptDelegate: PromptViewDelegate?
    
    // Keep track of which attribute is being changed within the prompt view
    var changingAttribute: Constants.UserAttribute = .none
    var changingAttributeName: String = ""
    
    // Easily accessible references to important PromptView elements
    var textField: UITextField!
    var label: UILabel!
    
    
    // MARK: Initialization
    /** View frame initializer override */
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        
        // Dimmed view appears on top of self.view, but under popup view
        let dimmedView = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        dimmedView.alpha = 0.8
        dimmedView.backgroundColor = UIColor.black
        dimmedView.tag = 2000
        
        // Custom view to contain the popup
        let popupView = UIView(frame: CGRect(x: 20, y: frame.height / 4, width: frame.width - 40, height: 220))
        popupView.layer.cornerRadius = 5
        popupView.layer.opacity = 1.0
        popupView.alpha = 1.0
        popupView.backgroundColor = UIColor.white
        popupView.tag = 1000
        
        // Label is added to the popup view
        label = UILabel(frame: CGRect(x: 0, y: 20, width: popupView.bounds.size.width, height: 20))
        label.textColor = Constants.Colors.primaryDark
        label.textAlignment = .center
        label.font = Constants.Fonts.lightTitle
        label.text = "Enter a new \(changingAttributeName)"
        
        // Text field is added to the popup view
        textField = UITextField(frame: CGRect(x: 20, y: 50, width: popupView.bounds.size.width - 40, height: 34))
        textField.placeholder = "Tap to type"
        textField.font = Constants.Fonts.regularText
        textField.tag = 4000
        textField.spellCheckingType = UITextSpellCheckingType.no
        textField.autocorrectionType = UITextAutocorrectionType.no
        textField.autocapitalizationType = UITextAutocapitalizationType.none
        textField.borderStyle = UITextBorderStyle.roundedRect
        textField.backgroundColor = Constants.Colors.primaryAccent
        textField.layer.cornerRadius = Constants.Radius.regularRadius
        textField.textColor = Constants.Colors.primaryDark
        
        // Button is added to the popup view
        let button = UIButton(frame: CGRect(x: 30, y: popupView.bounds.size.height - 70, width: popupView.bounds.size.width - 60, height: 50))
        button.addTarget(self, action: #selector(changeCommitted), for: UIControlEvents.touchUpInside)
        button.backgroundColor = Constants.Colors.primaryDark
        button.contentHorizontalAlignment = .center
        button.setTitle("Save Changes", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = Constants.Fonts.lightTitle
        button.layer.cornerRadius = Constants.Radius.regularRadius
        
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

    
    /** Required view initializer */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    // MARK: PromptViewDelegate
    /** Handles pressing the button to confirm changes in the PromptView */
    func changeCommitted() {
        dismissKeyboard()
        
        if let change = textField.text {
            promptDelegate?.didCommitChange(value: change)
        }
    }
    
    
    /** Dismisses the keyboard and tells the PromptViewDelegate that the change was cancelled */
    func dismissPopup() {
        dismissKeyboard()
        promptDelegate?.didCancelChange()
    }
    
    /** Sets the PromptView label with the given text, properly formatted */
    func setLabel(label: String) {
        self.label.text = "Enter a new " + label
    }
    
    
    /** Dismisses the keyboard presented to type into the PromptView text field */
    func dismissKeyboard() {
        self.viewWithTag(4000)?.resignFirstResponder()
    }
}
