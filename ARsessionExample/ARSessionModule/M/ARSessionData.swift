//
//  ARSessionData.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.
//

import Foundation
import ARKit
import RealityKit

enum ARSessionData {
    case initial
    case linkTo(arSession: ARSession)
    case createSuccess(threeDModelEntity: ThreeDModelEntity)
}
