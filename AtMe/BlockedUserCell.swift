//
//  BlockedUserCell.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-08-03.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

class BlockedUserCell: UITableViewCell {
    
    @IBOutlet var displayPictureImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var unblockButton: UIButton!
    
    @IBAction func didTapUnblockButton(_ sender: Any) {
    }
    
    var uid: String?
    var username: String?
}
