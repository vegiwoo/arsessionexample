//
//  SettingsApp.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.
//

import UIKit

final class SettingsApp {
    
    static var sizeUnit: CGFloat = (UIScreen.main.bounds.width > UIScreen.main.bounds.height ? UIScreen.main.bounds.width : UIScreen.main.bounds.height) / 30
    
    static var horizontalCellHeight = sizeСalculation(value: 70)
    
    static var hightTextFieldsAndButtons = sizeСalculation(value: 40)
    
    public static func sizeСalculation (value : CGFloat) -> CGFloat {
        return UIDevice.current.userInterfaceIdiom == .phone ? value : value * 1.5
    }
    
    // prefixes
    static var modelARAnchorPrefix  : String = "modelARAnchor"
    static var modelEntityPrefix    : String = "modelEntity"
    static var parentEntityPrefix   : String = "parentEntity"
    static var anchorEntityPrefix   : String = "anchorEntity"
}
