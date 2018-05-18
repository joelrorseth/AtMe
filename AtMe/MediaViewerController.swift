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
    
    // Provide the UIImage to the UIImageView
    if let image = image {
      contentImageView.image = image
    } else { print("Error: No image provided to MediaViewerController") }
    
    let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(MediaViewerController.viewTapped))
    view.addGestureRecognizer(tapRecognizer)
  }

  // Handler for tap gesture on the view
  @objc func viewTapped() {
    dismiss(animated: true, completion: nil)
  }
}


// MARK: UIScrollViewDelegate
extension MediaViewerController: UIScrollViewDelegate {
  
  // Provide the view to be scaled when zooming in the UIScrollView
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return contentImageView
  }
}
