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
  
  // Provide an animation object to handle presenting a view controller
  func animationController(forPresented presented: UIViewController,
    presenting: UIViewController, source: UIViewController)
    -> UIViewControllerAnimatedTransitioning? {
      
      let presentationAnimator = PresentationAnimator()
      presentationAnimator.openingFrame = openingFrame!
      return presentationAnimator
  }
  
  // Provide an animation object to handle dismissing a view controller
  func animationController(forDismissed dismissed: UIViewController)
    -> UIViewControllerAnimatedTransitioning? {
      
      let dismissAnimator = DismissalAnimator()
      dismissAnimator.openingFrame = openingFrame!
      return dismissAnimator
  }
}
