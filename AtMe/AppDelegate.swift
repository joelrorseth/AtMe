//
//  AppDelegate.swift
//  AtMe
//
//  Created by Joel Rorseth on 2017-02-18.
//  Copyright © 2017 Joel Rorseth. All rights reserved.
//

import UIKit
import UserNotifications
import Firebase
import OneSignal

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions
    launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
    UINavigationBar.appearance().barStyle = UIBarStyle.black
    
    let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false]
    
    // Init OneSignal
    OneSignal.initWithLaunchOptions(launchOptions, appId: Constants.App.oneSignalAppId,
                                    handleNotificationAction: nil, settings: onesignalInitSettings)
    
    OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification
    
    // Recommend moving the below line to prompt for push after informing the user about how your app will use them.
    OneSignal.promptForPushNotifications(userResponse: nil)
    
    // Enable offline data persistence to cache selected observed data and authenticated user
    FirebaseApp.configure()
    Database.database().isPersistenceEnabled = true
    
    return true
  }
}
