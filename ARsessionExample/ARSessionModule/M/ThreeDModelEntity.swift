//
//  ThreeDModelEntity.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 04.12.2020.
//

import Foundation
import RealityKit
import Combine

/// An entity representing a 3D model for working in an AR session
class ThreeDModelEntity  {

    // MARK: Vars && lets
    /// A UUID string that uniquely identifies the model instance
    let uuidString = UUID().uuidString
    /// Model ID
    let modelId: Int
    /// Model name
    var modelName: String
    
    // MARK: Names
    /// Name for ARAnchor model
    var arAnchorName: String = ""
    /// Name for  modelEntity model
    var modelEntityName: String = ""
    /// Name for parentEntity model
    var parentEntityName: String = ""
    /// Name for anchorEntity model
    var anchorEntityName: String = ""

    // MARK: Entities
    /// Represents the model itself as an Entity
    ///
    /// When a new value is received, initiates the creation of all accompanying entities
    var modelEntity: Entity? {
        didSet {
            if modelEntity != nil {
                self.creationOfAccompanyingEntities()
            }
        }
    }
    /// Represents the parent entity for modelEntity as ModelEntity
    var parentEntity: ModelEntity?
    /// Represents the parent entity for parentEntity as AnchorEntity
    var anchorEntity: AnchorEntity?
    
    // MARK: Transformations
    /// Transform the model to start placement
    var initialPlacementTransformation: Transform?
    /// Transform the model to end placement
    var finalPlacementTransformation: Transform?

    // MARK: Events && subscribers
    /// Event publisher for model
    public let threeDModelEntityPublisher = ThreeDModelEntityPublisher()
    /// Subscriber to event of loading model from file
    var loadModelEntityEvent: AnyCancellable?

    //var collisionSubs: [Cancellable] = []
    
    // MARK: Init && deinit
    init(modelId: Int, url: URL) {
        self.modelId = modelId
        self.modelName = String(url.lastPathComponent.replacingOccurrences(of: ".usdz", with: ""))

        self.makeEntitiesNames()
        self.loadAsyncModelEntity(from: url)
    }
    
    /// Async loads Entity at given URL
    /// - Parameters:
    ///   - url: URL of model to load
    fileprivate func loadAsyncModelEntity(from url: URL) {
        self.loadModelEntityEvent = Entity
            .loadAsync(contentsOf: url, withName: self.modelName)
            .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                #if DEBUG
                print("[DEBUG]: Model \(self.modelName) loading completed successfully")
                #endif
                self.loadModelEntityEvent?.cancel()
            case .failure(let error):
                #if DEBUG
                print("[DEBUG]: Model \(self.modelName) loading error - \(error)")
                #endif
                self.loadModelEntityEvent?.cancel()
            }
        }, receiveValue: { entity in
            self.modelEntity = entity
        })
    }
    
    
    /// Creates accompanying entities for Entity 3D model
    ///
    /// - the Entity itself is named
    /// - created and named parentEntity
    /// - Entity is added to parentEntity as a child entity
    /// - CollisionComponent is created for parentEntity (in order to further add gestures)
    /// - anchorEntity is created and named
    /// - parentEntity is added to the anchorEntity as a child entity
    /// - the initial and final positions of the parentEntity transformation are calculated to place the object on the scene
    /// - an event is published about the completion of the preparation of the entity for placement on scene
    fileprivate func creationOfAccompanyingEntities() {
        
        // modelEntity naming
        guard let modelEntity = self.modelEntity else { return }
        modelEntity.name = modelEntityName

        // add parentEntiry
        self.parentEntity = ModelEntity()
        guard let parentEntity = self.parentEntity else { return }
        parentEntity.name = parentEntityName
        parentEntity.addChild(modelEntity)
        
        // add collision to parentEntiry
        let entityBounds = modelEntity.visualBounds(relativeTo: parentEntity)
        parentEntity.collision = self.makeNormalCollisionComponent(entityBounds: entityBounds)
        
        // anchorEntity
        self.anchorEntity = AnchorEntity(plane: .any)
        guard let anchorEntity = self.anchorEntity else { return }
        anchorEntity.name = anchorEntityName
        anchorEntity.addChild(parentEntity)
        
        // transformation
        // remember target dimensions of model
        self.finalPlacementTransformation = parentEntity.transform
        // zero out size of model for smooth appearance
        self.initialPlacementTransformation = Transform(scale: SIMD3<Float>(repeating: 0.00),
                                                        rotation: self.finalPlacementTransformation!.rotation,
                                                        translation: self.finalPlacementTransformation!.translation)
        self.parentEntity?.transform = initialPlacementTransformation!
        
        // publish event
        self.threeDModelEntityPublisher.publish(request: .readinessForPlacement(threeDModelEntity: self))
    }
    
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
    
    /// Creates names for modelEntity, parentEntity and anchorEntity of model.
    /// - Parameter arAnchorName: ARAnchor name for forming names (optional).
    /// - Returns: Tuple of names (arAnchorName, modelEntityName, parentEntityName, anchorEntityName).
    fileprivate func makeEntitiesNames(arAnchorName: String? = nil) {
        if let arAnchorName = arAnchorName {
            // for example: 'modelARAnchor_1_69701c87-21f1-4ba7-8c2d-8854bb6ba65e'
            let aranchorNameSubstrings = arAnchorName.split(separator: "_")
            let modelIdString = String(aranchorNameSubstrings[1])
            let modelExampleUUIDString = String(aranchorNameSubstrings[2])
            /*
             for example:
             ('modelEntity_1_69701c87-21f1-4ba7-8c2d-8854bb6ba65e','parentEntity_1_69701c87-21f1-4ba7-8c2d-8854bb6ba65e', 'anchorEntity_1_69701c87-21f1-4ba7-8c2d-8854bb6ba65e')
             */
            self.arAnchorName = arAnchorName
            self.modelEntityName = "\(SettingsApp.modelEntityPrefix)_\(modelIdString)_\(modelExampleUUIDString)"
            self.parentEntityName = "\(SettingsApp.parentEntityPrefix)_\(modelIdString)_\(modelExampleUUIDString)"
            self.anchorEntityName = "\(SettingsApp.anchorEntityPrefix)_\(modelIdString)_\(modelExampleUUIDString)"
        } else{
            self.arAnchorName = "\(SettingsApp.modelARAnchorPrefix)_\(String(self.modelId))_\(self.uuidString)"
            self.modelEntityName = "\(SettingsApp.modelEntityPrefix)_\(String(self.modelId))_\(self.uuidString)"
            self.parentEntityName = "\(SettingsApp.parentEntityPrefix)_\(String(self.modelId))_\(self.uuidString)"
            self.anchorEntityName =  "\(SettingsApp.anchorEntityPrefix)_\(String(self.modelId))_\(self.uuidString)"
        }
    }
}

/// Event publisher for ThreeDModelEntity
class ThreeDModelEntityPublisher {
    var publisherRequest: AnyPublisher<ThreeDModelEntityPublisherRequest, Never> {
        subjectRequest.eraseToAnyPublisher()
    }
    
    private let subjectRequest = PassthroughSubject<ThreeDModelEntityPublisherRequest, Never>()
    
    private(set) var request : ThreeDModelEntityPublisherRequest? = nil {
        didSet {
            if let request = request {
                subjectRequest.send (request)
            }
        }
    }
    
    func publish(request: ThreeDModelEntityPublisherRequest) {
        self.request = request
    }
}

/// Types of events for ThreeDModelEntity
///
/// - `readinessForPlacement` - completion of preparation of entity, ready for placement on scene
enum ThreeDModelEntityPublisherRequest {
    case readinessForPlacement(threeDModelEntity: ThreeDModelEntity)
}
