//
//  ReportUserViewController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-08-03.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

class ReportUserViewController: UIViewController, AlertController {
    
    var violatorUid: String = ""
    var violatorUsername: String = ""
    var convoID: String = ""

    @IBAction func didPressSpamButton(_ sender: UIButton) {
        AuthController.reportUser(uid: violatorUid, username: violatorUsername, violation: "Spam", convoID: convoID)
        presentSimpleAlert(title: "Report Submitted", message: Constants.Messages.didReportUser, completion: { _ in
            self.navigationController?.popViewController(animated: true)
        })
    }
    
    @IBAction func didPressNudityButton(_ sender: Any) {
        AuthController.reportUser(uid: violatorUid, username: violatorUsername, violation: "Nudity", convoID: convoID)
        presentSimpleAlert(title: "Report Submitted", message: Constants.Messages.didReportUser, completion: { _ in
            self.navigationController?.popViewController(animated: true)
        })
    }
    
    @IBAction func didPressHarassmentButton(_ sender: Any) {
        AuthController.reportUser(uid: violatorUid, username: violatorUsername, violation: "Harassment", convoID: convoID)
        presentSimpleAlert(title: "Report Submitted", message: Constants.Messages.didReportUser, completion: { _ in
            self.navigationController?.popViewController(animated: true)
        })
    }
    
    @IBAction func didPressAbuseButton(_ sender: Any) {
        AuthController.reportUser(uid: violatorUid, username: violatorUsername, violation: "Abuse", convoID: convoID)
        presentSimpleAlert(title: "Report Submitted", message: Constants.Messages.didReportUser, completion: { _ in
            self.navigationController?.popViewController(animated: true)
        })
    }
    
    @IBAction func didObjectionableContentButton(_ sender: Any) {
        AuthController.reportUser(uid: violatorUid, username: violatorUsername, violation: "Content", convoID: convoID)
        presentSimpleAlert(title: "Report Submitted", message: Constants.Messages.didReportUser, completion: { _ in
            self.navigationController?.popViewController(animated: true)
        })
    }
    
    override func viewDidLoad() {
        self.title = "Report User"
    }
}
