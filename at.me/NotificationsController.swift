//
//  NotificationsController.swift
//  at.me
//
//  Created by Joel Rorseth on 2017-06-20.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import OneSignal

class NotificationsController {
    
    
    /**
     Send a push notification to a specified user
     - parameters:
        - userID: The userID of the user whom you intend to deliver the notification to
        - title: The title of the push notification. This should be the name of the sender.
        - message: The message to be displayed in the push notification. This should be the text of a message.
     */
    public static func send(to userID: String, title: String, message: String) {
     
        let jsonMessage: [AnyHashable: Any]! = ["contents": ["en": message],
            "headings": ["en": title], "include_player_ids": [userID],
            "ios_badgeType": "Increase", "ios_badgeCount": 1]
        
        OneSignal.postNotification(jsonMessage, onSuccess: { _ in
            // TODO: In future update, implement callback / UI update to show "delivered"
            
        }, onFailure: { _ in
            print("Notification could not be delivered")
        })
    }
    
    
    /** Obtain the notificationID of the current authorized user */
    public static func currentUserNotificationsID() -> String? {
        
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()

//        let hasPrompted = status.permissionStatus.hasPrompted
//        print("hasPrompted = \(hasPrompted)")
//        
//        let userStatus = status.permissionStatus.status
//        print("userStatus = \(userStatus)")
//        
//        let isSubscribed = status.subscriptionStatus.subscribed
//        print("isSubscribed = \(isSubscribed)")
//        
//        let userSubscriptionSetting = status.subscriptionStatus.userSubscriptionSetting
//        print("userSubscriptionSetting = \(userSubscriptionSetting)")
        
        let userID = status.subscriptionStatus.userId
        
//        print("userID = \(userID ?? "Not set")")
//
//        let pushToken = status.subscriptionStatus.pushToken
//        print("pushToken = \(pushToken ?? "Not set")")

        return userID
    }
}
