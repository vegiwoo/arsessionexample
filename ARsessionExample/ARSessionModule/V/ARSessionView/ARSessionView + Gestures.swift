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
         
    // MARK: GestureRecognizers
    /// Create gestures to manipulate model in the current view
    func makeScreenUIRecognizers() {
        self.makeScreenUIPanGestureRecognizer()
        self.makeScreenUIRotationGestureRecognizer()
        self.makeScreenUIPinchGestureRecognizer()
    }
    
    /// Removing gestures to manipulate model in the current view
    func killScreenUIRecognizers() {
        self.killScreenUIPanGestureRecognizer()
        self.killScreenUIRotationGestureRecognizer()
        self.killScreenUIPinchGestureRecognizer()
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
    fileprivate func killScreenUIPanGestureRecognizer () {
        self.arView.gestureRecognizers?.removeAll(where: {type(of: $0) == UIPanGestureRecognizer.self})
    }
    
    /// Add screen gesture recognizers related to `UIRotationGestureRecognizer`.
    fileprivate func makeScreenUIRotationGestureRecognizer () {
        let rotateRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(self.rotationGestureRecognizerHandler(sender:)))
        self.arView.addGestureRecognizer(rotateRecognizer)
    }
    
    /// Removes active gesture recognizers related to`UIRotationGestureRecognizer`.
    fileprivate func killScreenUIRotationGestureRecognizer () {
        self.arView.gestureRecognizers?.removeAll(where: {type(of: $0) == UIRotationGestureRecognizer.self})
    }
    
    /// Add screen gesture recognizers related to `UIPinchGestureRecognizer`.
    fileprivate func makeScreenUIPinchGestureRecognizer () {
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchGestureRecognizerHandler(sender:)))
        self.arView.addGestureRecognizer(pinchRecognizer)
    }
    
    /// Removes active gesture recognizers related to`UIPinchGestureRecognizer`.
    fileprivate func killScreenUIPinchGestureRecognizer() {
        self.arView.gestureRecognizers?.removeAll(where: {type(of: $0) == UIPinchGestureRecognizer.self})
    }
    
    // MARK: GestureRecognizers handlers
    /// UITapGestureRecognizer handler.
    /// - Parameter sender: UITapGestureRecognizer as sender.
    @objc func tapGestureRecognizerHandler (sender: UITapGestureRecognizer) {
        
        guard sender.view == self.arView,
              let parentEntity = (sender.view as! ARView).entity(at: sender.location(in: arView)) as? ModelEntity,
              let modelEntity = parentEntity.children.first,
              let anchorEntity = parentEntity.parent as? AnchorEntity
        else { return }

        self.anchorEntityEditable = anchorEntity
        
        // calculating position and transformation of model to rise above scene
        let newTranslation = SIMD3<Float>(x: parentEntity.transform.translation.x,
                                          y: parentEntity.transform.translation.y + 0.10,
                                          z: parentEntity.transform.translation.z)
        let transform = Transform(scale: parentEntity.transform.scale,
                                  rotation: parentEntity.transform.rotation,
                                  translation: newTranslation)
        // moving
        self.startEditingMoving = parentEntity.move(to: transform,
                                                    relativeTo: anchorEntity,
                                                    duration: 0.8,
                                                    timingFunction: .easeIn)
        self.startEditingMovingComplete = self.arView.scene
            .publisher(for: AnimationEvents.PlaybackCompleted.self)
            .filter{$0.playbackController == self.startEditingMoving}
            .sink{ _ in
                // overriding CollisionComponent
                let entityBounds = modelEntity.visualBounds(relativeTo: parentEntity)
                parentEntity.collision = self.makeEditingCollisionComponent(entityBounds: entityBounds)
                // add gestures
                //self.arView.installGestures([.scale], for: parentEntity)
                
                self.presentationMode = .editing
                // gestures
                self.makeScreenUIRecognizers()
                self.killUITapGestureRecognizer()
                // levitation animation
                self.makeLevitation(modelEntity: parentEntity)
            }
        
    }

    /// UIPanGestureRecognizer handler.
    /// - Parameter sender: UIPanGestureRecognizer as sender.
    @objc func panGestureRecognizerHandler(sender: UIPanGestureRecognizer) {
        guard self.arView == sender.view,
              let parentEntity = arView.entity(at: sender.location(in: arView)) as? ModelEntity,
              let anchorEntity = parentEntity.parent,
              let planeShadowEntity = anchorEntity.children.first(where: {$0.name.hasPrefix(SettingsApp.planeShadowPrefix)})
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
                let newTranslationParentEntity = SIMD3<Float>(x: parentEntity.transform.translation.x - relativeTranslation.x,
                                                               y: parentEntity.transform.translation.y,
                                                               z: parentEntity.transform.translation.z - relativeTranslation.z)
                // move parentEntity
                parentEntity.move(to: Transform(scale: parentEntity.transform.scale,
                                                rotation: parentEntity.transform.rotation,
                                                translation: newTranslationParentEntity), relativeTo: anchorEntity)
                // move planeShadowEntity
                let newTranslationPlaneShadowEntity = SIMD3<Float>(x: planeShadowEntity.transform.translation.x - relativeTranslation.x,
                                                                   y: planeShadowEntity.transform.translation.y,
                                                                   z: planeShadowEntity.transform.translation.z - relativeTranslation.z)
                
                planeShadowEntity.move(to: Transform(scale: planeShadowEntity.transform.scale, rotation: planeShadowEntity.transform.rotation, translation: newTranslationPlaneShadowEntity), relativeTo: anchorEntity)
                
                // start animation of levitation
                self.makeLevitation(modelEntity: parentEntity)
            }
        }
    }

    /// UIRotationGestureRecognizer handler.
    /// - Parameter sender: UIRotationGestureRecognizer as sender..
    @objc func rotationGestureRecognizerHandler (sender: UIRotationGestureRecognizer) {
        
        guard self.arView == sender.view,
              let parentEntity = arView.entity(at: sender.location(in: arView)) as? ModelEntity,
              let planeShadowEntity = parentEntity.parent?.children.first(where: {$0.name.hasPrefix(SettingsApp.planeShadowPrefix)})
        else { return }
        
        self.killLevitation(modelEntity: parentEntity)

        switch sender.state {
        case .possible, .began,.changed:
            let rotation = simd_quatf.init(angle: Float(sender.rotation), axis: SIMD3<Float>(x: 0, y: 1, z: 0))
            let newTranform = Transform(scale: parentEntity.transform.scale, rotation: rotation, translation: parentEntity.transform.translation)
            // parentEntity rotation
            parentEntity.transform = newTranform
            // planeShadowEntity rotation
            planeShadowEntity.transform.rotation = parentEntity.transform.rotation
        default:
            self.makeLevitation(modelEntity: parentEntity)
        }
    }
    
    @objc func pinchGestureRecognizerHandler (sender: UIPinchGestureRecognizer) {
        guard self.arView == sender.view,
              let parentEntity = arView.entity(at: sender.location(in: arView)) as? ModelEntity,
              let anchorEntity = parentEntity.parent,
              let planeShadowEntity = anchorEntity.children.first(where: {$0.name.hasPrefix(SettingsApp.planeShadowPrefix)})
        else { return }
        
        self.killLevitation(modelEntity: parentEntity)
        
        switch sender.state {
        case .possible, .began, .changed:
            parentEntity.setScale(SIMD3<Float>(x: Float(sender.scale),
                                               y: Float(sender.scale),
                                               z: Float(sender.scale)),
                                  relativeTo: anchorEntity)
            planeShadowEntity.setScale(SIMD3<Float>(x: Float(sender.scale),
                                                    y: Float(sender.scale),
                                                    z: Float(sender.scale)),
                                       relativeTo: anchorEntity)
        default:
            sender.scale = 1.0
            self.makeLevitation(modelEntity: parentEntity)
        }
    }
}
