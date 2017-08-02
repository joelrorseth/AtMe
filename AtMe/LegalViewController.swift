//
//  LegalViewController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-08-01.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

class LegalViewController: UIViewController {

    
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var mainTextView: UITextView!
    
    var terms: String = ""
    var privacy: String = "Privacy"
    
    
    /** Method called when view controller has been loaded */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // EXtract the policies from the included text files
        if let path = Bundle.main.path(forResource: "terms", ofType: "txt") {
            
            do { try terms = String(contentsOfFile: path) }
            catch _ as Error? {}
        }
        
        if let path = Bundle.main.path(forResource: "privacy", ofType: "txt") {
            
            do { try privacy = String(contentsOfFile: path) }
            catch _ as Error? {}
        }
        
        // Force statement load
        segmentedControlValueChanged(segmentedControl)
    }
    
    
    /** Called when done button is pressed inside view controller. */
    @IBAction func didPressDoneButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    
    /** Called when the segmented control changed it's selected value. */
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        if (sender.titleForSegment(at: sender.selectedSegmentIndex) == "Terms of Service") {
            mainTextView.text = terms
        } else {
            mainTextView.text = privacy
        }
    }
    
}
