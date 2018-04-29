//
//  MediaTransitionDelegate.swift
//  AtMe
//
//  Created by Joel Rorseth on 2018-04-28.
//  Copyright © 2018 Joel Rorseth. All rights reserved.
//

import UIKit

class MediaTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {

    var openingFrame: CGRect?
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let presentationAnimator = PresentationAnimator()
        presentationAnimator.openingFrame = openingFrame!
        return presentationAnimator
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let dismissAnimator = DismissalAnimator()
        dismissAnimator.openingFrame = openingFrame!
        return dismissAnimator
    }
}
