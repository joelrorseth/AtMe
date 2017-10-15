//
//  ChatToolbarView.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-07-28.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

class ChatToolbarView: UIInputView {

    private static let preferredHeight: CGFloat = 20.0
    
    let containerView = UIView()
    let expandingTextView = UITextView()
    
    
    // Lazy properties for all subviews of the toolbar
    let sendButton: UIButton = {
        let button = UIButton(type: UIButtonType.system)
        let titleString = NSLocalizedString("Send", comment: "")
        
        button.setTitleColor(Constants.Colors.primaryDark, for: UIControlState.normal)
        button.setTitle(titleString, for: UIControlState.normal)
        button.titleLabel?.font = Constants.Fonts.boldButtonText
        
        return button
    }()
    
    let libraryButton: UIButton = {
        let button = UIButton(type: UIButtonType.system)
        button.setImage(UIImage(named: "library"), for: UIControlState.normal)
        button.tintColor = Constants.Colors.primaryDark
        
        return button
    }()
    
    let cameraButton: UIButton = {
        let button = UIButton(type: UIButtonType.system)
        button.setImage(UIImage(named: "camera"), for: UIControlState.normal)
        button.tintColor = Constants.Colors.primaryDark
        
        return button
    }()
    
    private let separatorView: UIView = {
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        
        return separatorView
    }()
    
    
    /** Overriden variable which determines the intrinsic size for the content in the view. */
    override var intrinsicContentSize: CGSize {
        var newSize = bounds.size
        if expandingTextView.bounds.size.height > 0.0 {
            newSize.height = expandingTextView.bounds.size.height + 20.0
        }
        if newSize.height < ChatToolbarView.preferredHeight || newSize.height > 120.0 {
            newSize.height = ChatToolbarView.preferredHeight
        }
        return newSize
    }
    
    
    /** Required initializer. */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    /** Overridden method that asks view to calculate and return best size for self. */
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: ChatToolbarView.preferredHeight)
    }
    
    
    /** Overridden frame initializer. */
    override init(frame: CGRect, inputViewStyle: UIInputViewStyle) {
        super.init(frame: frame, inputViewStyle: inputViewStyle)
        
        // Add all elements of toolbar into the view, in order
        addSubview(containerView)
        addSubview(separatorView)
        containerView.addSubview(libraryButton)
        containerView.addSubview(cameraButton)
        containerView.addSubview(expandingTextView)
        containerView.addSubview(sendButton)
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.groupTableViewBackground
        
        // Separator setup
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.heightAnchor.constraint(equalToConstant: 1.2).isActive = true
        separatorView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        separatorView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        // Container view setup
        let guide = layoutMarginsGuide
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: guide.bottomAnchor).isActive = true
        containerView.leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true
        
        // Library Button setup
        libraryButton.translatesAutoresizingMaskIntoConstraints = false
        libraryButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: UILayoutConstraintAxis.horizontal)
        libraryButton.setContentHuggingPriority(UILayoutPriority(rawValue: 250), for: UILayoutConstraintAxis.horizontal)
        //libraryButton.bottomAnchor.constraint(equalTo: expandingTextView.bottomAnchor).isActive = true
        libraryButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: -10.0).isActive = true
        libraryButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        libraryButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        // Camera Button setup
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        cameraButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: UILayoutConstraintAxis.horizontal)
        cameraButton.setContentHuggingPriority(UILayoutPriority(rawValue: 250), for: UILayoutConstraintAxis.horizontal)
        //cameraButton.bottomAnchor.constraint(equalTo: expandingTextView.bottomAnchor).isActive = true
        cameraButton.leadingAnchor.constraint(equalTo: libraryButton.trailingAnchor, constant: 10.0).isActive = true
        cameraButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        cameraButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        // Expanding text view setup
        expandingTextView.text = Constants.Placeholders.messagePlaceholder
        //expandingTextView.spellCheckingType = .no
        //expandingTextView.autocorrectionType = .no
        //expandingTextView.autocapitalizationType = .none
        expandingTextView.textColor = UIColor.gray
        expandingTextView.font = Constants.Fonts.regularText
        expandingTextView.tintColor = UIColor.white
        expandingTextView.translatesAutoresizingMaskIntoConstraints = false
        expandingTextView.textContainer.heightTracksTextView = true
        expandingTextView.isScrollEnabled = false
        expandingTextView.setContentHuggingPriority(UILayoutPriority(rawValue: 249), for: UILayoutConstraintAxis.horizontal)
        expandingTextView.leadingAnchor.constraint(equalTo: cameraButton.trailingAnchor, constant: 10.0).isActive = true
        expandingTextView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10.0).isActive = true
        expandingTextView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10.0).isActive = true
        expandingTextView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10.0).isActive = true
        expandingTextView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 0.0)
        expandingTextView.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: UILayoutConstraintAxis.vertical)
        expandingTextView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        
        // Send Button setup
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: UILayoutConstraintAxis.horizontal)
        sendButton.setContentHuggingPriority(UILayoutPriority(rawValue: 250), for: UILayoutConstraintAxis.horizontal)
        //sendButton.bottomAnchor.constraint(equalTo: expandingTextView.bottomAnchor).isActive = true
        sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 10.0).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(greaterThanOrEqualToConstant: sendButton.frame.size.width).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        // Give a low priority leading constraint for text for when buttons are gone
        let constraint = expandingTextView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: -10)
        constraint.priority = UILayoutPriority.defaultLow
        constraint.isActive = true
    }
    
    
    /** Add all the removable media selection buttons back to the toolbar, along with constraints. */
    private func reAddPictureButtons() {
        
        // Add back into container view
        containerView.addSubview(libraryButton)
        containerView.addSubview(cameraButton)
        
        // Library Button setup
        libraryButton.translatesAutoresizingMaskIntoConstraints = false
        libraryButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: UILayoutConstraintAxis.horizontal)
        libraryButton.setContentHuggingPriority(UILayoutPriority(rawValue: 250), for: UILayoutConstraintAxis.horizontal)
        //libraryButton.bottomAnchor.constraint(equalTo: expandingTextView.bottomAnchor).isActive = true
        libraryButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: -10.0).isActive = true
        libraryButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        libraryButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        // Camera Button setup
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        cameraButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: UILayoutConstraintAxis.horizontal)
        cameraButton.setContentHuggingPriority(UILayoutPriority(rawValue: 250), for: UILayoutConstraintAxis.horizontal)
        //cameraButton.bottomAnchor.constraint(equalTo: expandingTextView.bottomAnchor).isActive = true
        cameraButton.leadingAnchor.constraint(equalTo: libraryButton.trailingAnchor, constant: 10.0).isActive = true
        cameraButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        cameraButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        self.expandingTextView.leadingAnchor.constraint(equalTo: self.cameraButton.trailingAnchor, constant: 10.0).isActive = true
    }
    
    
    // MARK: - Animations
    /** Commit to a text based message, meaning the media buttons will be animated off the toolbar. */
    func commitToTextBasedMessage() {
        
        // Remove leading constraint keeping text view anchored to camera icon
        self.expandingTextView.leadingAnchor.constraint(equalTo: self.cameraButton.trailingAnchor, constant: 10.0).isActive = false
        
        // Animate the buttons away, then remove from the container view
        UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: {

            self.libraryButton.alpha = 0
            self.cameraButton.alpha = 0

            self.expandingTextView.text = ""
            self.containerView.layoutIfNeeded()
        
        }, completion: { _ in
            
            self.libraryButton.removeFromSuperview()
            self.cameraButton.removeFromSuperview()
        })
    }
    
    
    /** Determine animations for the event that text has been cleared. User may now send picture message. */
    func uncommitToTextBasedMessage() {

        // Animate the buttons being added back onto the toolbar
        UIView.animate(withDuration: 0.45, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            
            self.libraryButton.alpha = 1
            self.cameraButton.alpha = 1
            
            self.expandingTextView.text = Constants.Placeholders.messagePlaceholder
            self.containerView.layoutIfNeeded()
            
        }, completion: { _ in
            
            self.reAddPictureButtons()
            self.containerView.layoutIfNeeded()
        })
    }
    
    
    /** Determine if the text view has text message currently.
    - returns: True if the text view has a message inside currently
    */
    func messageInProgress() -> Bool { return expandingTextView.text! != ""}
    
    
    /** Clears text entirely from the toolbar, leaving no placeholder. */
    func clearText() { expandingTextView.text = "" }
    
    
    /** Reset toolbar to docked state with placeholder message. */
    func resetToPlaceholder() {
        expandingTextView.text = Constants.Placeholders.messagePlaceholder
        
        // Add in in future update
        //uncommitToTextBasedMessage()
    }
}
