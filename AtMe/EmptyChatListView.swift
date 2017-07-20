//
//  EmptyChatListView.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-07-07.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit

protocol EmptyChatListDelegate {
    func didTapChatSomebody()
}

class EmptyChatListView: UIView {

    var emptyChatDelegate: EmptyChatListDelegate?
    
    /**
     The primary init method for creating this specialized view
     */
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    /**
     The required init method for creating this specialized view
     */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews()
    }

    /**
     A subview initializer method that establishes all other views in this view
     */
    private func initSubviews() {
        
        self.backgroundColor = Constants.Colors.tableViewBackground
        
        let label = UILabel()
        let somebodyButton = UIButton(type: .custom)
        //let randomButton = UIButton(type: .custom)
        
        // Both subviews must be in *this* view hierarchy before we can add constraints
        // This is because the constraints need to reference superviews, and will cause crash if not set
        
        self.addSubview(label)
        self.addSubview(somebodyButton)
        //self.addSubview(randomButton)

        // Label setup
        label.text = "You have no active conversations!"
        label.font = UIFont(name: "Avenir Next", size: 18)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -50).isActive = true
        
        // Chat user chat button setup
        somebodyButton.titleLabel?.font = UIFont(name: "Avenir Next Demi Bold", size: 18)
        somebodyButton.setTitleColor(UIColor.darkGray, for: .normal)
        somebodyButton.setTitleColor(UIColor.lightGray, for: .selected)
        somebodyButton.setTitle("@Somebody", for: .normal)
        somebodyButton.titleLabel?.textAlignment = NSTextAlignment.center
        somebodyButton.layer.cornerRadius = Constants.Radius.regularRadius
        somebodyButton.backgroundColor = Constants.Colors.primaryAccent
        somebodyButton.addTarget(self, action: #selector(chatSomebodyTapped), for: UIControlEvents.touchUpInside)
        
        somebodyButton.translatesAutoresizingMaskIntoConstraints = false
        somebodyButton.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        somebodyButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
        somebodyButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        somebodyButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10).isActive = true
        somebodyButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
        
        // TODO: Future update
//        // Random chat button setup
//        randomButton.titleLabel?.font = UIFont(name: "Avenir Next Demi Bold", size: 18)
//        randomButton.setTitleColor(UIColor.darkGray, for: .normal)
//        randomButton.setTitleColor(UIColor.lightGray, for: .selected)
//        randomButton.setTitle("@Random", for: .normal)
//        randomButton.titleLabel?.textAlignment = NSTextAlignment.center
//        randomButton.layer.cornerRadius = Constants.Radius.regularRadius
//        randomButton.backgroundColor = Constants.Colors.primaryAccent
//        randomButton.translatesAutoresizingMaskIntoConstraints = false
//        randomButton.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
//        randomButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
//        randomButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
//        randomButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10).isActive = true
//        randomButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
    }
    
    /**
     A convenience method that will attempt to call the delegate implementation of didTapChatSomebody()
     */
    func chatSomebodyTapped() {
        emptyChatDelegate?.didTapChatSomebody()
    }
}
