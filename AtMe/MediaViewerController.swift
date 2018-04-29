//
//  MediaViewerController.swift
//  AtMe
//
//  Created by Joel Rorseth on 2018-04-28.
//  Copyright © 2018 Joel Rorseth. All rights reserved.
//

import UIKit

class MediaViewerController: UIViewController {

    var contentImageView: UIImageView!
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        
        contentImageView = UIImageView(frame: self.view.frame)
        contentImageView.contentMode = UIViewContentMode.scaleAspectFit
        view.addSubview(contentImageView)
        
//        contentImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
//        contentImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
//        contentImageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
//        contentImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        if let image = image {
            contentImageView.image = image
        } else { print("Error: No image provided to MediaViewerController") }

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(MediaViewerController.viewTapped))
        view.addGestureRecognizer(tapRecognizer)
    }
    
    @objc func viewTapped() {
        dismiss(animated: true, completion: nil)
    }
}
