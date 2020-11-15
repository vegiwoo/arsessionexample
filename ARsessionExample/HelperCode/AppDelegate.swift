//
//  AppDelegate.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let arVC = ModulesBuilder.createArSessionModule()
        window = UIWindow()
        window?.rootViewController = arVC
        window?.makeKeyAndVisible()
        return true
    }
}
