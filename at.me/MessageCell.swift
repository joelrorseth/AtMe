//
//  MessageCell.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-02-20.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

class MessageCell: UICollectionViewCell {
    
    // Static references to resizable chat bubbles
    static let outgoingBubble = UIImage(named: "outgoing_bubble")!
        .resizableImage(withCapInsets: UIEdgeInsetsMake(22, 26, 22, 26)).withRenderingMode(.alwaysTemplate)

    static let incomingBubble = UIImage(named: "incoming_bubble")!
        .resizableImage(withCapInsets: UIEdgeInsetsMake(22, 26, 22, 26)).withRenderingMode(.alwaysTemplate)
    
    
    // MARK: Lazy properties for UI message elements
    // ==========================================
    // ==========================================
    // Container UIView for bubble image
    let bubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        return view
    }()
    
    // Text view for message content
    let messageTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: CGFloat(Constants.Text.defaultTextSize))
        textView.text = ""
        textView.isEditable = false
        textView.backgroundColor = UIColor.clear
        return textView
    }()
    
    // Image view for bubble
    let bubbleImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
        imageView.image = MessageCell.incomingBubble
        imageView.tintColor = UIColor(white: 0.90, alpha: 1)
        
        return imageView
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
        
        // The message and container view are subviews of cell
        addSubview(bubbleView)
        addSubview(messageTextView)
        
        // The image view for bubble graphic is added to container view
        bubbleView.addSubview(bubbleImageView)

        // Important: Set up constraints to allow bubble image to dynamically resize
        bubbleView.addConstraintsWithFormat(format: "H:|[v0]|", views: bubbleImageView)
        bubbleView.addConstraintsWithFormat(format: "V:|[v0]|", views: bubbleImageView)
    }
}


// MARK: UIView Extension
extension UIView {
    
    // ==========================================
    // ==========================================
    func addConstraintsWithFormat(format: String, views: UIView...) {
        
        var viewsDict = [String: UIView]()
        for (index, view) in views.enumerated() {
            viewsDict["v\(index)"] = view
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDict))
    }
}
