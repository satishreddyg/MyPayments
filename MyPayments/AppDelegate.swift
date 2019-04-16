//
//  AppDelegate.swift
//  MyPayments
//
//  Created by Satish Garlapati on 7/28/18.
//  Copyright © 2018 Blackmoon. All rights reserved.
//

import UIKit
import AWSMobileClient

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        AWSDDLog.add(AWSDDTTYLogger.sharedInstance)
        AWSDDLog.sharedInstance.logLevel = .info
        
        if (CognitoIdentityUserPoolId == "YOUR_USER_POOL_ID") {
            let alertController = UIAlertController(title: "Invalid Configuration",
                                                    message: "Please configure user pool constants in Constants.swift file.",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)
            
            self.window?.rootViewController!.present(alertController, animated: true, completion:  nil)
        }
        
        // setup logging
        AWSDDLog.sharedInstance.logLevel = .verbose
        return AWSMobileClient.sharedInstance().interceptApplication(
            application,
            didFinishLaunchingWithOptions: launchOptions)
    }
}
