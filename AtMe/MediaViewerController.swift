//
//  MediaViewerController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2018-04-28.
//  Copyright © 2018 Joel Rorseth. All rights reserved.
//

import UIKit

class MediaViewerController: UIViewController {
  
  var scrollView: UIScrollView!
  var contentImageView: UIImageView!
  var popupNavigationBar: MediaViewerNavigationBar!
  
  var image: UIImage?
  
  
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
    popupNavigationBar = MediaViewerNavigationBar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 100))
    popupNavigationBar.viewerDelegate = self
    view.addSubview(popupNavigationBar)
    
    popupNavigationBar.translatesAutoresizingMaskIntoConstraints = false
    popupNavigationBar.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
    popupNavigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    popupNavigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    popupNavigationBar.heightAnchor.constraint(equalToConstant: 200).isActive = true
    
    
    // Provide the UIImage to the UIImageView
    if let image = image {
      contentImageView.image = image
    } else { print("Error: No image provided to MediaViewerController") }
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
    dismiss(animated: true, completion: nil)
  }
  
  func didPressSave() {
    dismiss(animated: true, completion: nil)
  }
}
