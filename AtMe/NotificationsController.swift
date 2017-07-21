//
//  NotificationsController.swift
//  AtMe
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
    
    
    /** Obtain the notificationID of the current authorized user 
     - returns: An optional String representation of the current user's notification ID, if found
     */
    public static func currentDeviceNotificationID() -> String? {
        
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        let userID = status.subscriptionStatus.userId

        return userID
    }
}
