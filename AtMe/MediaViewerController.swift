//
//  MediaViewerController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2018-04-28.
//  Copyright © 2018 Joel Rorseth. All rights reserved.
//

import UIKit

protocol MediaViewerDelegate {
  func didFinishViewing()
}

class MediaViewerController: UIViewController {
  
  var scrollView: UIScrollView!
  var contentImageView: UIImageView!
  var popupNavigationBar: MediaViewerNavigationBar!
  
  var viewerDelegate: MediaViewerDelegate?
  
  var image: UIImage?
  var navBarIsVisible: Bool = true
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = UIColor.black
    
    scrollView = UIScrollView(frame: view.frame)
    scrollView.minimumZoomScale = 1.0
    scrollView.maximumZoomScale = 5.0
    scrollView.delegate = self
    
    contentImageView = UIImageView(frame: self.view.frame)
    contentImageView.contentMode = UIViewContentMode.scaleAspectFit
    
    // Form view hierarchy -- UIView -> UIScrollView -> UIImageView
    view.addSubview(scrollView)
    scrollView.addSubview(contentImageView)
    
    // Place a navigation bar at the top under the status bar
    popupNavigationBar = MediaViewerNavigationBar()
    popupNavigationBar.viewerDelegate = self
    
    // TODO
    view.addSubview(popupNavigationBar)
    
    popupNavigationBar.translatesAutoresizingMaskIntoConstraints = false
    popupNavigationBar.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
    popupNavigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    popupNavigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    popupNavigationBar.isOpaque = false
    
    // Provide the UIImage to the UIImageView
    if let image = image {
      contentImageView.image = image
    } else { print("Error: No image provided to MediaViewerController") }
    
    let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(MediaViewerController.viewTapped))
    view.addGestureRecognizer(tapRecognizer)
  }
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
  
  // Handler for tap gesture on the view
  @objc func viewTapped() {
    
    navBarIsVisible = !navBarIsVisible
    
    // Show/hide the navigation bar when the picture is tapped normally (single tap)
    UIView.animate(withDuration: 0.24, animations: {
      self.popupNavigationBar.alpha = self.navBarIsVisible ? 1.0 : 0.0
    })
  }
}


// MARK: UIScrollViewDelegate
extension MediaViewerController: UIScrollViewDelegate {
  
  // Provide the view to be scaled when zooming in the UIScrollView
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return contentImageView
  }
}


// MARK: MediaViewerBarDelegate
extension MediaViewerController: MediaViewerBarDelegate {
  
  // Handle the Done and Save buttons being pressed in the navigation bar
  func didPressDone() {
    viewerDelegate?.didFinishViewing()
    dismiss(animated: true, completion: nil)
  }
  
  func didPressSave() {
    dismiss(animated: true, completion: nil)
  }
}
