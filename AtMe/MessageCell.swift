//
//  MessageCell.swift
//  AtMe
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
        textView.backgroundColor = UIColor.clear
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets.zero
        return textView
    }()
    
    // Image view for picture messages
    let messageImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = UIViewContentMode.scaleAspectFill
        imageView.layer.cornerRadius = 12
        imageView.layer.masksToBounds = true
        imageView.image = nil
        return imageView
    }()
    
    
    // MARK: Initializers
    /** Cell initializer override */
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupViews()
    }
    
    
    /** Required initializer */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupViews()
    }
    
    
    /** Set up the look and feel of this cell and related views. */
    func setupViews() {
        
        messageImageView.tag = 1000
        
        // The message and bubble view are subviews of cell
        self.addSubview(bubbleView)
        self.addSubview(messageTextView)
        self.addSubview(messageImageView)
    }
    
    
    /** Add the message image view into the cell (self) */
    func addImageView() {
        self.addSubview(messageImageView)
    }
    
    
    /** Setup self for text message */
    func setupTextMessage(outgoing: Bool, size: CGSize, containerWidth: CGFloat) {
        setupEntireMessage(isText: true, isOutgoing: outgoing,
                           messageSize: size, containerWidth: containerWidth)
    }
    
    
    /** Setup self for picture message */
    func setupPictureMessage(outgoing: Bool, size: CGSize, containerWidth: CGFloat) {
        setupEntireMessage(isText: false, isOutgoing: outgoing,
                           messageSize: size, containerWidth: containerWidth)
    }
    
    
    /** Setup the message content view and bubble */
    private func setupEntireMessage(isText: Bool, isOutgoing: Bool, messageSize: CGSize, containerWidth: CGFloat) {
        
        
        // Determine correct margins, insets and sizes for message bubble depending on type of message
        // Picture messages will eclipse the bubble entirely, text messages have padding
        
        let bubbleWidth = messageSize.width + (2 * MessageCell.horizontalBubbleSpacing)
        let bubbleHeight = messageSize.height + (2 * MessageCell.verticalBubbleSpacing)
        let messageView = isText ? messageTextView : messageImageView
        
        if (isOutgoing) {
            
            bubbleView.backgroundColor = UIColor.white
            messageTextView.textColor = UIColor.black
            
            // Outgoing messages appear on the right, so offset starting x,y using padding and message width
            bubbleView.frame = CGRect(x: containerWidth - messageSize.width -
                (MessageCell.horizontalInsetPadding + (2 * MessageCell.horizontalBubbleSpacing)),
                                      y: MessageCell.verticalInsetPadding,
                                      width: bubbleWidth,
                                      height: bubbleHeight)
            
            // Picture messages need to take up the entire bubble
            if !isText { messageView.frame = bubbleView.frame; return }
            
            messageView.frame = CGRect(x: containerWidth - messageSize.width -
                (MessageCell.horizontalInsetPadding + MessageCell.horizontalBubbleSpacing),
                                    y: MessageCell.verticalInsetPadding + MessageCell.verticalBubbleSpacing,
                                    width: messageSize.width,
                                    height: messageSize.height)
            
            
        } else {
            
            bubbleView.backgroundColor = Constants.Colors.primaryDark
            messageTextView.textColor = UIColor.white
            
            // Incoming messages appear on the left, so starting x,y should be near the padding cutoff
            bubbleView.frame = CGRect(x: MessageCell.horizontalInsetPadding, y: MessageCell.verticalInsetPadding,
                                      width: bubbleWidth, height: bubbleHeight)
            
            // Picture messages need to take up the entire bubble
            if !isText { messageView.frame = bubbleView.frame; return }
            
            messageView.frame = CGRect(x: MessageCell.horizontalInsetPadding + MessageCell.horizontalBubbleSpacing,
                                    y: MessageCell.verticalInsetPadding + MessageCell.verticalBubbleSpacing,
                                    width: messageSize.width,
                                    height: messageSize.height)
        }
    }
    
    
    /** Called in preparation of a cell of this subclass being reused in a table view */
    override func prepareForReuse() {
        imageView?.image = nil
        messageImageView.image = nil
        
        // Remove the image view entirely from this cell
        // This is the only we I found to avoid zombie images in reused cells, so manually add/remove
        viewWithTag(1000)?.removeFromSuperview()
    }
}
