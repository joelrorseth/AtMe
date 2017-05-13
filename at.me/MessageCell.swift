//
//  MessageCell.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-02-20.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

class MessageCell: UICollectionViewCell {
    
    
    // MARK: Lazy properties for UI message elements
    // ==========================================
    // ==========================================
    // UIView for outside chat bubble
    let bubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()
    
    // Text view for message content
    let messageTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: CGFloat(Constants.Text.defaultTextSize))
        textView.isEditable = false
        textView.backgroundColor = UIColor.clear
        return textView
    }()
    
    
    // MARK: Initializers
    // ==========================================
    // Seems to be called after view is loaded
    // ==========================================
    override init(frame: CGRect) {
        super.init(frame: frame)
        
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
        addSubview(bubbleView)
        addSubview(messageTextView)
    }
}
