//
//  SettingsApp.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.
//

import UIKit

final class SettingsApp {
    static var sizeUnit: CGFloat = (UIScreen.main.bounds.width > UIScreen.main.bounds.height ? UIScreen.main.bounds.width : UIScreen.main.bounds.height) / 30
    
    public static func sizeСalculation (value : CGFloat) -> CGFloat {
        return UIDevice.current.userInterfaceIdiom == .phone ? value : value * 1.5
    }
}
