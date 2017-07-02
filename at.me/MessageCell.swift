//
//  MessageCell.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-02-20.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

class MessageCell: UITableViewCell {
    
    public static let horizontalInsetPadding: CGFloat = 16
    public static let verticalInsetPadding: CGFloat = 3
    
    public static let horizontalBubbleSpacing: CGFloat = 8
    public static let verticalBubbleSpacing: CGFloat = 8
    
    // MARK: Lazy properties for UI message elements
    // ==========================================
    // ==========================================
    // UIView for outside chat bubble
    let bubbleView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.shadowOffset = CGSize(width: 0, height: 1.4)
        view.layer.shadowColor = UIColor.lightGray.cgColor
        view.layer.shadowOpacity = 0.5
        view.layer.shadowRadius = 2.0
        view.layer.cornerRadius = Constants.Radius.regularRadius
        view.layer.masksToBounds = false
        return view
    }()
    
    
    // Text view for message content
    let messageTextView: UITextView = {
        let textView = UITextView()
        textView.font = Constants.Fonts.regularText
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor.clear       // Change back to clear
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets.zero
        return textView
    }()
    
    // TODO: Figure out a better way to clip to a mask (bubbleView)
    let messageImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        imageView.layer.cornerRadius = 12
        imageView.layer.masksToBounds = true
        //imageView.backgroundColor = UIColor.blue    // Remove later
        return imageView
    }()
    
    
    // MARK: Initializers
    // ==========================================
    // Seems to be called after view is loaded
    // ==========================================
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupViews()
    }
    
    // ==========================================
    // Seems to be called when view is first loaded
    // ==========================================
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupViews()
    }
    
    // ==========================================
    // ==========================================
    func setupViews() {
        
        // The message and bubble view are subviews of cell
        //self.layer.masksToBounds = true
        self.addSubview(bubbleView)
        self.addSubview(messageTextView)
        self.addSubview(messageImageView)
    }
}
