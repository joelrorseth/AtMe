//
//  ConvoAuxViewController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-08-01.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

class ConvoAuxViewController: UIViewController {

    var username: String = ""
    var convoID: String = ""
    var uid: String = ""
    
    @IBOutlet var displayPictureImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var blockUserButton: UIButton!
    @IBOutlet var reportUserButton: UIButton!
    
    
    /** Handle user pressing the Block User button. */
    @IBAction func didPressBlockUserButton(_ sender: UIButton) {
    }

    
    /** Handle user pressing the Report User button. */
    @IBAction func didPressReportUserButton(_ sender: Any) {
    }
    
    
    /** Method called when view is loaded onto screen. */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DatabaseController.downloadImage(into: displayPictureImageView, from: "displayPictures/\(uid)/\(uid).JPG", completion: { _ in
            self.displayPictureImageView.layer.masksToBounds = true
            self.displayPictureImageView.layer.cornerRadius = self.displayPictureImageView.frame.size.width / 2
        })
        
        AuthController.findNameFor(uid: uid, completion: { name in
            if let name = name { self.nameLabel.text = name }
        })

        blockUserButton.layer.cornerRadius = Constants.Radius.regularRadius
        reportUserButton.layer.cornerRadius = Constants.Radius.regularRadius
        
        usernameLabel.text = "@\(username)"
    }
}
