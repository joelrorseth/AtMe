//
//  BlockedUserCell.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-08-03.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

// Protocol defines methods that will be called in response to interactions in the cell
protocol BlockedUserCellDelegate {
    func didTapUnblock(button: UIButton, uid: String, username: String)
}


class BlockedUserCell: UITableViewCell {
    
    var blockUserCellDelegate: BlockedUserCellDelegate?
    var uid: String?
    var username: String?
    
    @IBOutlet var displayPictureImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var unblockButton: UIButton!
    
    @IBAction func didTapUnblockButton(_ sender: UIButton) {
        
        guard let uid = self.uid, let username = self.username else { return }
        blockUserCellDelegate?.didTapUnblock(button: sender, uid: uid, username: username)
    }
}
