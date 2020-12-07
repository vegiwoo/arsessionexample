//
//  ARSessionView + ARSession.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 07.12.2020.
//

import Foundation
import UIKit
import RealityKit

extension ARSessionView {
    
    // MARK: TargetShape
    /// Creates a target shape.
    /// - Parameters:
    ///   - width: Diameter of the celt form in meters.
    ///   - texturing: Texture is used (optional).
    /// - Returns: AnchorEntity of the created target form.
    func makeTargetShape(width: Float, texturing: Bool) -> AnchorEntity {
        
        let meshResource = MeshResource.generatePlane(width: width, depth: width)
        var texture: TextureResource?
        var material: UnlitMaterial!
        
        if texturing {
            do {
                if let textureURL = Bundle.main.url(forResource: "targetShapeTexture_001", withExtension: "png", subdirectory: "Files") {
                    texture = try TextureResource.load(contentsOf: textureURL)
                    material = UnlitMaterial()
                    material!.baseColor = .texture (texture!)
                    material!.tintColor = UIColor(red: 0.89, green: 0.89, blue: 0.91, alpha: 0.45)
                    
                } else {
                    material = UnlitMaterial(color: .systemGray3)
                }
            } catch {
                material = UnlitMaterial(color: .systemGray3)
            }
        } else {
            material = UnlitMaterial(color: .systemGray3)
        }
        
        // modelEntity
        let modelEntity = ModelEntity(mesh: meshResource, materials: [material])
        modelEntity.name = "modelEntity_targetShape"
        
        // anchorEntity
        let anchorEntity = AnchorEntity(plane: .any)
        anchorEntity.addChild(modelEntity)
        anchorEntity.name = "anchorEntity_targetShape"
        return anchorEntity
    }
    
    /// Receives changes for target form and moves it to a new value.
    /// - Parameters:
    ///   - transform: Changes for target shape (coordinates for placement/ movement).
    func changesToTargetShape(transform: simd_float4x4) {
        if self.targetShape == nil { self.targetShape = makeTargetShape(width: 0.4, texturing: true)}
        
        if !arView.scene.anchors.contains(where: {$0 == self.targetShape!}) {
            arView.scene.addAnchor(self.targetShape!)
        }
        guard let targetShape = self.targetShape else { return }
        targetShape.move(to: transform, relativeTo: nil, duration: 0.4, timingFunction: .easeOut)
    }
    
    /// Remove target shape from scene.
    func killTargetShape() {
        guard let targetShape = self.targetShape,
              arView.scene.anchors.contains(where: {$0 == targetShape}),
              let targetShapeModelEntity = targetShape.children.first as? ModelEntity,
              let targetShapeWorldTransform = self.targetShapeWorldTransform
        else { return }
        
        let targetTranslation = SIMD3(targetShapeWorldTransform.columns.3.x,
                                      targetShapeWorldTransform.columns.3.y,
                                      targetShapeWorldTransform.columns.3.z)
        
        self.killTargetShapeMoving = targetShapeModelEntity.move(to: Transform(scale:SIMD3<Float>(repeating: 0.01), rotation:  self.targetShape!.transform.rotation, translation: targetTranslation), relativeTo: self.targetShape!, duration: 0.1, timingFunction: .easeOut)
        self.killTargetShapeMovingComplete = arView.scene
            .publisher(for: AnimationEvents.PlaybackCompleted.self)
            .filter{$0.playbackController == self.killTargetShapeMoving}
            .sink{ _ in
                self.arView.scene.anchors.remove(self.targetShape!)
                self.targetShape = nil
                self.killTargetShapeMoving = nil
                self.killTargetShapeMovingComplete?.cancel()
            }
    }
    
    // MARK: CollisionComponent
    /// Creates CollisionComponent for ModelEntity (normal mode).
    /// - Parameter entityBounds: BoundingBox.
    func makeNormalCollisionComponent (entityBounds: BoundingBox) -> CollisionComponent{
        return CollisionComponent(shapes: [ShapeResource.generateBox(size: entityBounds.extents).offsetBy(translation: entityBounds.center)], mode: .trigger, filter: .sensor)
    }
    
    /// Creates a CollisionComponent for the ModelEntity (edit mode).
    /// - Parameter entityBounds: BoundingBox.
    func makeEditingCollisionComponent (entityBounds: BoundingBox) -> CollisionComponent {
        return CollisionComponent(shapes: [ShapeResource.generateSphere(radius: 3.0).offsetBy(translation: entityBounds.center)], mode: .default, filter: .default)
    }
}
