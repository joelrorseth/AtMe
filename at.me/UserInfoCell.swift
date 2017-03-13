//
//  UserInfoCell.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-02-25.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

class UserInfoCell: UITableViewCell {

    @IBOutlet weak var displayImage: UIImageView!
    @IBOutlet weak var displayName: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    
    var uid: String?
    var username: String?
}
