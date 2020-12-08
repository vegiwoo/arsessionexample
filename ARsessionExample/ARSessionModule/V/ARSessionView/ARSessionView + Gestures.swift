//
//  ARSessionView + Gestures.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 02.12.2020.
//

import UIKit
import RealityKit

// Work with gestures
extension ARSessionView {
    
    /// Create gestures to manipulate model in the current view
    func makeScreenUIRecognizers() {
        self.makeScreenUIPanGestureRecognizer()
        self.makeScreenUIRotationGestureRecognizer()
    }
    
    /// Removing gestures to manipulate model in the current view
    func killScreenUIRecognizers() {
        self.killUIPanGestureRecognizer()
        self.killUIRotationGestureRecognizer()
    }

    /// Add screen gesture recognizers related to `UITapGestureRecognizer`.
    func makeScreenUITapGestureRecognizer () {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapGestureRecognizerHandler(sender:)))
        self.arView.addGestureRecognizer(tapRecognizer)
    }
    
    /// Removes active gesture recognizers related to`UITapGestureRecognizer`.
    func killUITapGestureRecognizer () {
        self.arView.gestureRecognizers?.removeAll(where: {type(of: $0) == UITapGestureRecognizer.self})
    }
    
    /// Add screen gesture recognizers related to `UIPanGestureRecognizer`.
    fileprivate func makeScreenUIPanGestureRecognizer() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerHandler))
        self.arView.addGestureRecognizer(panGestureRecognizer)
    }
    
    /// Removes active gesture recognizers related to`UIPanGestureRecognizer`.
    fileprivate func killUIPanGestureRecognizer () {
        self.arView.gestureRecognizers?.removeAll(where: {type(of: $0) == UIPanGestureRecognizer.self})
    }
    
    /// Add screen gesture recognizers related to `UIRotationGestureRecognizer`.
    fileprivate func makeScreenUIRotationGestureRecognizer () {
        let rotateRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(self.rotationGestureRecognizerHandler(sender:)))
        self.arView.addGestureRecognizer(rotateRecognizer)
    }
    
    /// Removes active gesture recognizers related to`UIRotationGestureRecognizer`.
    fileprivate func killUIRotationGestureRecognizer () {
        self.arView.gestureRecognizers?.removeAll(where: {type(of: $0) == UIRotationGestureRecognizer.self})
    }

    /// UIPanGestureRecognizer handler.
    /// - Parameter sender: UIPanGestureRecognizer.
    @objc func panGestureRecognizerHandler(sender: UIPanGestureRecognizer) {
        guard self.arView == sender.view,
              let parentEntity = arView.entity(at: sender.location(in: arView)) as? ModelEntity,
              let anchorEntity = parentEntity.parent
        else { return }
        
        if sender.state == .changed {
            let raycast = arView.raycast(from: sender.location(in: arView), allowing: .existingPlaneGeometry, alignment: .any)

            if let transform = raycast.first?.worldTransform {
                self.newTranslation = SIMD3<Float>(x: transform.columns.3.x,
                                                   y: transform.columns.3.y,
                                                   z: transform.columns.3.z)
               // self.modelPlacementPoint = self.newTranslation
                
            }
            if let relativeTranslation = relativeTranslation {
                // stop the levitation animation
                self.killLevitation(modelEntity: parentEntity)
                // move to new position
                parentEntity.move(to: Transform(scale: parentEntity.transform.scale,
                                                rotation: parentEntity.transform.rotation,
                                                translation: SIMD3<Float>(x: parentEntity.transform.translation.x - relativeTranslation.x,
                                                                          y: parentEntity.transform.translation.y,
                                                                          z: parentEntity.transform.translation.z - relativeTranslation.z)),
                                  relativeTo: anchorEntity)
                // start animation of levitation
                self.makeLevitation(modelEntity: parentEntity)
            }
        }
    }

    /// UIRotationGestureRecognizer handler.
    /// - Parameter sender: UIRotationGestureRecognizer.
    @objc func rotationGestureRecognizerHandler (sender: UIRotationGestureRecognizer) {
        
        guard self.arView == sender.view,
              let parentEntity = arView.entity(at: sender.location(in: arView)) as? ModelEntity
        else { return }
        
        self.killLevitation(modelEntity: parentEntity)

        switch sender.state {
        case .possible, .began,.changed:
            let rotation = simd_quatf.init(angle: Float(sender.rotation), axis: SIMD3<Float>(x: 0, y: 1, z: 0))

            let newTranform = Transform(scale: parentEntity.transform.scale, rotation: rotation, translation: parentEntity.transform.translation)
            
            parentEntity.transform = newTranform
        case .ended, .cancelled, .failed:
            self.makeLevitation(modelEntity: parentEntity)
   
        @unknown default:
            self.makeLevitation(modelEntity: parentEntity)
        }
    }
}
