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
    /// Add screen gesture recognizers related to `UITapGestureRecognizer`.
    func makeScreenUITapGestureRecognizers () {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapGestureRecognizerHandler(sender:)))
        arView.addGestureRecognizer(tapRecognizer)
    }
    
    /// Removes active gesture recognizers related to`UITapGestureRecognizer`.
    func killUITapGestureRecognizers () {
        arView.gestureRecognizers?.removeAll(where: {type(of: $0) == UITapGestureRecognizer.self})
    }
    
    /// Add screen gesture recognizers related to `UIPanGestureRecognizer`.
    func makeScreenUIPanGestureRecognizers() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerHandler))
        arView.addGestureRecognizer(panGestureRecognizer)
    }
    
    /// Removes active gesture recognizers related to`UIPanGestureRecognizer`.
    func killUIPanGestureRecognizers () {
        arView.gestureRecognizers?.removeAll(where: {type(of: $0) == UIPanGestureRecognizer.self})
    }
    
    @objc func panGestureRecognizerHandler(sender: UIPanGestureRecognizer) {
        guard self.arView == sender.view,
              let parentEntity = arView.entity(at: sender.location(in: arView)),
              let anchorEntity = parentEntity.parent
        else { return }
        
        if sender.state == .changed {
            let raycast = arView.raycast(from: sender.location(in: arView), allowing: .existingPlaneGeometry, alignment: .any)
            if let transform = raycast.first?.worldTransform {
                self.newTranslation = SIMD3<Float>(x: transform.columns.3.x, y: transform.columns.3.y, z: transform.columns.3.z)
                self.modelPlacementPoint = self.newTranslation
                
            }
            if let relativeTranslation = relativeTranslation {
                parentEntity.move(to: Transform(scale: parentEntity.transform.scale,
                                                rotation: parentEntity.transform.rotation,
                                                translation: SIMD3<Float>(x: parentEntity.transform.translation.x - relativeTranslation.x,
                                                                          y: parentEntity.transform.translation.y,
                                                                          z: parentEntity.transform.translation.z - relativeTranslation.z)),
                                  relativeTo: anchorEntity)
            }
        }
    }
}
