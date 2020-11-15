//  ARSessionView.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.

import UIKit
import ARKit
import RealityKit
import Combine
import FocusEntity

/// Class for the ArSession view
class ARSessionView : UIView {
    
    enum ARSessionViewPresentationMode {
        case initial, placing, editing
    }
    
    var viewData: ARSessionData = .initial {
        didSet {
            self.setNeedsLayout()
        }
    }
    var arCoachingOverlayView : ARCoachingOverlayView!
    var arSessionViewEvent : ARSessionViewEvent!
    
    // UI cotrols
    lazy var arView : ARView = self.makeArView()
    // - Buttons
    lazy var modelButton    : UIButton = makeFunctionalButton(sfSymbolName: "cube.fill")
    lazy var settingsButton : UIButton = makeFunctionalButton(sfSymbolName: "gear")
    lazy var succsessButton : UIButton = makeFunctionalButton(sfSymbolName: "checkmark.circle.fill")
    lazy var canceledButton : UIButton = makeFunctionalButton(sfSymbolName: "xmark.circle.fill")
    lazy var trashButton    : UIButton = makeFunctionalButton(sfSymbolName: "trash.circle.fill")
    
    var presentationMode : ARSessionViewPresentationMode! {
        willSet {
            if newValue != nil {
                self.changingStackFunctionality()
            }
        }
    }
    var initialButtonStack : UIStackView?
    var placingButtonStack : UIStackView?
    var editingButtonStack : UIStackView?
    
    var placingModelEntity : ModelEntity? {
        willSet {
            if newValue != nil {
                self.presentationMode = .placing
            } else {
                self.presentationMode = .initial
            }
        }
    }
    
    // vars for edit model
    var anchorEntityEditable : AnchorEntity?

    var anchorEntityEditableTransform : Transform?
    var anchorEntityEditableTranslation : SIMD3<Float>?
    
    // animating
    var deletingMoving : AnimationPlaybackController!
    var deletingMovingcomplete : AnyCancellable?
    var editingMoving : AnimationPlaybackController!
    var editingComplete : AnyCancellable?
    
    // target shape
    var detectPlacementPointForTargetShape: Bool! {
        didSet {
            if detectPlacementPointForTargetShape == false {
                self.deleteteTargetShape()
            }
        }
    }
    var targetShapeWorldTransform : simd_float4x4? {
        willSet {
            if let newValue = newValue {
                self.changesToTargetShape(transform: newValue)
            }
        }
    }
    var targetShape : AnchorEntity?
    var deletingTargetShapeMoving: AnimationPlaybackController!
    var deletingTargetShapeMovingComplete : AnyCancellable?

    // init
    init(frame: CGRect, arSessionViewEvent: ARSessionViewEvent) {
        self.arSessionViewEvent = arSessionViewEvent
        super.init(frame: frame)
        
        self.setupView()
        self.setupConstrains()
        self.addGestures()
    
        self.presentationMode = ARSessionViewPresentationMode.initial
        self.detectPlacementPointForTargetShape = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addGestures() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizerHandler(sender:)))
        self.arView.addGestureRecognizer(tapRecognizer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        switch viewData {
        case .initial:
            print("DEBUG: ARSessionView viewData initial - \(Date())")
            break
        case .linkTo(arSession: let arSession):
            self.arView.session = arSession
            self.arView.session.delegate = self
            self.arCoachingOverlayView = makeCoachingOverlayView(goal: .anyPlane)
            self.arView.addSubview(arCoachingOverlayView)
            arCoachingOverlayView.edgesToSuperview()
            self.arView.bringSubviewToFront(self.arCoachingOverlayView)
            self.arCoachingOverlayView.session = arSession
            self.arCoachingOverlayView.delegate = self.arView
        case .createSuccess(let modelEntity):
            if self.placingModelEntity == nil {
                self.placingModelEntity = modelEntity
            }
        }
    }
    
    // MARK: Action handlers
    /// Tap handler for an existing model to start editing it.
    /// - Parameter sender: UITapGestureRecognizer as sender.
    @objc func tapGestureRecognizerHandler (sender: UITapGestureRecognizer) {

        guard sender.view == self.arView else { fatalError()} // TODO: !! !

        let entities = (sender.view as! ARView).entities(at: sender.location(in: sender.view))
        if let parentEntity = entities.first as? ModelEntity,
           //let modelEntity = parentEntity.children.first as? ModelEntity,
           let anchorEntity = parentEntity.parent as? AnchorEntity {
  
            self.anchorEntityEditable = anchorEntity

            let newTranslation = SIMD3<Float>(x: parentEntity.transform.translation.x,
                                              y: parentEntity.transform.translation.y + 0.10,
                                              z: parentEntity.transform.translation.z)
            let transform = Transform(scale: parentEntity.transform.scale, rotation: parentEntity.transform.rotation, translation: newTranslation)
           
            parentEntity.move(to: transform, relativeTo: anchorEntity, duration: 0.8, timingFunction: .easeIn)
            self.arView.installGestures(for: parentEntity)
            
            self.presentationMode = .editing
        }
    }
    
    /// Tap handler for modelButton and publish '.createModelEntityFromFile' request.
    /// - Parameter sender: UIButton as sender.
    @objc func modelButtonTapHandler(sender: UIButton) {
        self.arSessionViewEvent.publish(request: .createModelEntityFromFile)
        
    }
    
    /// Tap handler for settingsButton and publish '.showSettingsPage' request.
    /// - Parameter sender: UIButton as sender.
    @objc func settingsButtonTapHandler(sender: UIButton) {
        self.arSessionViewEvent.publish(request: .showSettingsPage)
    }
    
    /// Tap handler for successButton and placing new model on scene.
    /// - Parameter sender:  UIButton as sender.
    @objc func successButtonPlacing (sender: UIButton) {
        if let placingModelEntity = self.placingModelEntity {

            let uuidString = UUID().uuidString
        
            // parentEntiry
            let parentEntity = ModelEntity()
            parentEntity.name = "parentEntity-\(uuidString)"
            parentEntity.addChild(placingModelEntity)
 
            // add collision
            let entityBounds = placingModelEntity.visualBounds(relativeTo: parentEntity)
            parentEntity.collision = CollisionComponent(shapes: [ShapeResource.generateBox(size: entityBounds.extents).offsetBy(translation: entityBounds.center)])
 
            // anchorEntity
            let anchorEntity = AnchorEntity(plane: .any)
            anchorEntity.name = "anchorEntity-\(uuidString)"
            anchorEntity.addChild(parentEntity)

            // placing
            let targetTransform = parentEntity.transform
            
            let newTransform = Transform(scale: SIMD3<Float>(repeating: 0.00), rotation: targetTransform.rotation, translation: targetTransform.translation)
            parentEntity.transform = newTransform
  
            self.arView.scene.addAnchor(anchorEntity)
            
            parentEntity.move(to: targetTransform, relativeTo: anchorEntity, duration: 0.3, timingFunction: .easeIn)
 
            self.placingModelEntity = nil
            self.viewData = .initial
        }
    }
    
    /// Tap handler on cancelButton when canceling model placement.
    /// - Parameter sender: UIButton as sender.
    @objc func cancelButtonPlacing (sender: UIButton) {
        self.placingModelEntity = nil
        self.viewData = .initial
    }
    
    /// Tap handler on successButton when model is finished editing.
    /// - Parameter sender: UIButton as sender.
    @objc func successButtonEditing (sender: UIButton) {
        
        if self.anchorEntityEditable != nil,
           let parentEntity = self.anchorEntityEditable!.children.first as? ModelEntity {
            
            let newTranslation = SIMD3<Float>(x: parentEntity.transform.translation.x,
                                              y: parentEntity.transform.translation.y - 0.10,
                                              z: parentEntity.transform.translation.z)

            let newTransformform = Transform(scale: parentEntity.transform.scale, rotation: parentEntity.transform.rotation, translation: newTranslation)

            self.editingMoving = parentEntity.move(to: newTransformform, relativeTo: anchorEntityEditable!, duration: 0.8, timingFunction: .easeInOut)
            
            self.editingComplete = self.arView.scene.publisher(for: AnimationEvents.PlaybackCompleted.self)
                .filter{$0.playbackController == self.editingMoving}
                .sink{ _ in
                    // remove gestureRecognizers using filter RealityKit.EntityTranslationGestureRecognizer
                    if let entitiesGesures = self.arView.gestureRecognizers?.filter({$0 is RealityKit.EntityTranslationGestureRecognizer}), entitiesGesures.count > 0 {
                        entitiesGesures.forEach {gesture in
                            self.arView.removeGestureRecognizer(gesture)
                        }
                    }
                    self.anchorEntityEditable = nil
                    self.presentationMode = .initial
                }
        }
    }
    
    /// Tap handler on trashButton - animation and model deletion
    /// - Parameter sender: UIButton as sender.
    @objc func trashButtonEditing (sender: UIButton) {

        if let anchorEnity = self.anchorEntityEditable,
           let parentEntity = anchorEnity.children.first as? ModelEntity {
            
            let newTranslation = SIMD3<Float>(x: parentEntity.transform.translation.x,
                                              y: parentEntity.transform.translation.y - 0.10,
                                              z: parentEntity.transform.translation.z)
            let newScale = SIMD3<Float>(x: 0.00, y: 0.00, z: 0.00)
            
            // define and start animation before deleting the model
            deletingMoving = parentEntity.move(to: Transform(scale:newScale, rotation: parentEntity.transform.rotation, translation: newTranslation), relativeTo: parentEntity, duration: 0.3, timingFunction: .easeOut)

            // subscribe to animation end event before deleting model, deleting
            deletingMovingcomplete = self.arView.scene.publisher(for: AnimationEvents.PlaybackCompleted.self)
                .filter{$0.playbackController == self.deletingMoving}
                .sink{ _ in
                    self.arView.scene.anchors.remove(anchorEnity)
                    self.deletingMoving = nil
                    self.deletingMovingcomplete?.cancel()
                    self.presentationMode = .initial
                }
        }
    }
    
    func changesToTargetShape(transform: simd_float4x4) {
        if self.targetShape == nil { self.targetShape = makeTargetShape()}
        if !self.arView.scene.anchors.contains(where: {$0 == self.targetShape!}) {
            self.targetShape!.move(to: transform, relativeTo: nil)
            self.arView.scene.addAnchor(self.targetShape!)
        } else {
            self.targetShape!.move(to: transform, relativeTo: nil, duration: 0.4, timingFunction: .easeOut)
        }
    }

    func makeTargetShape() -> AnchorEntity {

        var material : UnlitMaterial!
        var texture : TextureResource?

        do {
            if let textureURL = Bundle.main.url(forResource: "targetShapeTexture_001", withExtension: "png") {
                texture = try TextureResource.load(contentsOf: textureURL)

                
            }
        } catch  {
            print("\(error.localizedDescription)")
        }
        
        // material
        if let texture = texture {
            material = UnlitMaterial()
            material!.baseColor = .texture(texture)
            material!.tintColor = UIColor(red: 25, green: 25, blue: 25, alpha: 0.5)
        } else {
            material = UnlitMaterial()
            material.baseColor = .color(.red)
        }
    
        // modelEntity
        let mesh = MeshResource.generatePlane(width: 0.3, depth: 0.3, cornerRadius: 2)
        
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])
        modelEntity.name = "targetShape_modelEntity"
        // anchorEntity
        let anchorEntity = AnchorEntity(plane: .any)
        anchorEntity.addChild(modelEntity)
        anchorEntity.name = "anchorEntity"
        return anchorEntity
    }
    
    func deleteteTargetShape() {
        if self.targetShape != nil {
            if self.arView.scene.anchors.contains(where: {$0 == self.targetShape!}) {
                self.deletingTargetShapeMoving = self.targetShape!.move(to: Transform(scale:SIMD3<Float>(repeating: 0.00), rotation:  self.targetShape!.transform.rotation, translation:  self.targetShape!.transform.translation), relativeTo: self.targetShape!, duration: 0.3, timingFunction: .easeOut)
                
                self.deletingTargetShapeMovingComplete = self.arView.scene.publisher(for: AnimationEvents.PlaybackCompleted.self)
                    .filter{$0.playbackController == self.deletingTargetShapeMoving}
                    .sink{ _ in
                        self.arView.scene.anchors.remove(self.targetShape!)
                        self.targetShape = nil
                        self.deletingTargetShapeMoving = nil
                        self.deletingTargetShapeMovingComplete?.cancel()
                    }
            }
        }
    }
}

class ARSessionViewEvent {
    var publisherRequest: AnyPublisher<ARSessionViewEventRequest, Never> {
        subjectRequest.eraseToAnyPublisher()
    }
    
    private let subjectRequest = PassthroughSubject<ARSessionViewEventRequest, Never>()
    
    private(set) var request : ARSessionViewEventRequest? = nil {
        didSet {
            if let request = request {
                subjectRequest.send (request)
            }
        }
    }
    
    func publish(request: ARSessionViewEventRequest) {
        self.request = request
    }
}

enum ARSessionViewEventRequest {
    case createModelEntityFromFile
    case showSettingsPage 
}


extension ARSessionView : ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if detectPlacementPointForTargetShape {
            
            // Center point of self.arView
            let location = self.arView.center
            
            let raycast = self.arView.raycast(from: location, allowing: .existingPlaneGeometry, alignment: .any)
            
            if let worldTransform = raycast.first?.worldTransform {
                self.targetShapeWorldTransform = worldTransform
            }
        }
    }
}

extension ARView : ARCoachingOverlayViewDelegate {

    public func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        // Do something
    }
    
    
    public func coachingOverlayViewDidDeactivate (_ coachingOverlayView: ARCoachingOverlayView) {
        // Do something
    }
}

extension CustomARView : FocusEntityDelegate {
    public func toTrackingState() {
        // Do something
    }
    
    public func toInitializingState() {
        // Do something
    }
}

class CustomARView : ARView {
    
    var focusEntity : FocusEntity!
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)

        focusEntity =  FocusEntity(on: self, style: .classic(color: .red))
        focusEntity.delegate = self
        focusEntity.setAutoUpdate(to: true)
    }
    
    @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
