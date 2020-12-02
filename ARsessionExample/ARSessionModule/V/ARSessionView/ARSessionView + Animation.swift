//
//  ARSessionView + Animation.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 02.12.2020.
//

import Foundation
import RealityKit

extension ARSessionView {
    /// Implements timer levitation animation for ModelEntity
    /// - Parameter modelEntity: ModelEntity for animation implementation.
    func makeLevitation (modelEntity: ModelEntity) {

        let kinematics: PhysicsBodyComponent = .init(massProperties: PhysicsMassProperties(mass: 3.0), material: nil, mode: .kinematic)
        modelEntity.components.set(kinematics)

        let motion : PhysicsMotionComponent = .init(linearVelocity:  [0, 0.03, 0], angularVelocity: [0, 0, 0])
        modelEntity.components.set(motion)
        
        var up = true; var down = false
        
        levitationTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            if up {
                modelEntity.components[PhysicsMotionComponent] = .init(linearVelocity:  [0, -0.03, 0], angularVelocity: [0, 0, 0])
                down = true; up = false
            } else if down {
                modelEntity.components[PhysicsMotionComponent] = .init(linearVelocity:  [0, 0.03, 0], angularVelocity: [0, 0, 0])
                down = false; up = true
            }
        }
    }
    
    /// Stops timer and removes levitation animation for ModelEntity.
    /// - Parameter modelEntity: ModelEntity to remove animation.
    func killLevitation (modelEntity: ModelEntity) {
        levitationTimer?.invalidate()
        levitationTimer = nil

        modelEntity.components.remove(PhysicsBodyComponent.self)
        modelEntity.components.remove(PhysicsMotionComponent.self)
    }
}
