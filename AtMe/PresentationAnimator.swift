//
//  PresentationAnimator.swift
//  AtMe
//
//  Created by Joel Rorseth on 2018-04-28.
//  Copyright © 2018 Joel Rorseth. All rights reserved.
//

import UIKit

class PresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    var openingFrame: CGRect?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let containerView = transitionContext.containerView
        
        let animationDuration = self .transitionDuration(using: transitionContext)
        
        // add blurred background to the view
        let fromViewFrame = fromViewController.view.frame
        
        UIGraphicsBeginImageContext(fromViewFrame.size)
        fromViewController.view.drawHierarchy(in: fromViewFrame, afterScreenUpdates: true)
        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let snapshotView = toViewController.view.resizableSnapshotView(from: toViewController.view.frame,
            afterScreenUpdates: true, withCapInsets: UIEdgeInsets.zero) else { return }
        
        snapshotView.frame = openingFrame!
        containerView.addSubview(snapshotView)
        
        toViewController.view.alpha = 0.0
        containerView.addSubview(toViewController.view)
        
        UIView.animate(withDuration: animationDuration, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 20.0, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
            
            snapshotView.frame = fromViewController.view.frame
            
        }) { (finished) in
            snapshotView.removeFromSuperview()
            toViewController.view.alpha = 1.0
            
            transitionContext.completeTransition(finished)
        }
    }
}
