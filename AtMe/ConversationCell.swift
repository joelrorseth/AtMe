//
//  ConversationCell.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-03-15.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

class ConversationCell: UITableViewCell {
    
    @IBOutlet weak var cellBackgroundView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var recentMessageLabel: UILabel!
    @IBOutlet weak var userDisplayImageView: UIImageView!
    @IBOutlet weak var recentMessageTimeStampLabel: UILabel!
    @IBOutlet var newMessageIndicator: UIView!
    
    
    // MARK: Initializers
    /** Cell initializer override */
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    
    /** Required initializer */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
