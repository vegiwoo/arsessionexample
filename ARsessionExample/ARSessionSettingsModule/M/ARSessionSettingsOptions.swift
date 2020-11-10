//
//  ARSessionSettingsOptions.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.
//

import Foundation

/// Represents options for customization
class ARSessionSettingsOptions : Hashable  {
    let name        : String
    let group       : ARSessionSettingsOptionsGroup
    let description : String
    var isSelected  : Bool
    
    init(key: ARSessionSettingsOptionsKeys, group: ARSessionSettingsOptionsGroup, isSelected: Bool) {
        self.name = key.name
        self.description = key.description
        self.group = group
        self.isSelected = isSelected
    }

    static func == (lhs: ARSessionSettingsOptions, rhs: ARSessionSettingsOptions) -> Bool {
        lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

/// Represents a group of options to customize
enum ARSessionSettingsOptionsKeys : Int, CaseIterable {
    case detectHorizontalPlanesOnly
    case detectVerticalPlanesOnly
    case detectAllPlanes
    case turnOffPlaneDetection
    
    var name : String {
        switch self {
        case .detectHorizontalPlanesOnly:
            return "Horizontal planes"
        case .detectVerticalPlanesOnly:
            return "Vertical planes"
        case .detectAllPlanes:
            return "All planes"
        case .turnOffPlaneDetection:
            return "Turn off"
        }
    }
    
    var description : String {
        switch self {
        case .detectHorizontalPlanesOnly:
            return "Only detect horizontal planes"
        case .detectVerticalPlanesOnly:
            return "Only detect vertical planes"
        case .detectAllPlanes:
            return "Detect horizontal and vertical planes"
        case .turnOffPlaneDetection:
            return "Disable all planes detection"
        }
    }
}

/// Represents a group of options to customize
enum ARSessionSettingsOptionsGroup : Int, CaseIterable {
    case planeDetectionMode
    
    var description : String {
        switch self {
        case .planeDetectionMode:
            return "Plane detection mode"
        }
    }
}
