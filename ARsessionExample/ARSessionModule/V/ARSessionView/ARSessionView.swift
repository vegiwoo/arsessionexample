//  ARSessionView.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.

import UIKit
import ARKit
import RealityKit
import Combine

/// Class for ArSession view
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
    
    var placingModelEntity : Entity? {
        willSet {
            if newValue != nil {
                self.presentationMode = .placing
            } else {
                self.presentationMode = .initial
            }
        }
    }
    var names: (arAnchorName: String, modelEntityName: String, parentEntityName: String, anchorEntityName: String)?
    var initialPlacementTransformation: Transform?
    var finalPlacementTransformation: Transform?
    
    // vars for edit model
    var anchorEntityEditable : AnchorEntity?
    var anchorEntityEditableTransform : Transform?
    var anchorEntityEditableTranslation : SIMD3<Float>?
    
    // animating
    var deletingMoving : AnimationPlaybackController!
    var deletingMovingcomplete : AnyCancellable?
    var startEditingMoving: AnimationPlaybackController!
    var startEditingMovingComplete: AnyCancellable?
    var endEditingMoving : AnimationPlaybackController!
    var endEditingMovingComplete : AnyCancellable?
    
    // target shape
    var detectPlacementPointForTargetShape: Bool! {
        didSet {
            if detectPlacementPointForTargetShape == false {
                self.killTargetShape()
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
    // -- kill TargetShape AnimationPlaybackController
    var killTargetShapeMoving: AnimationPlaybackController!
    // -- kill TargetShape subscriber
    var killTargetShapeMovingComplete : AnyCancellable?

    // levitation
    var levitationTimer : Timer?
    var baseLevitationPoint: SIMD3<Float>?

    // for gestures
    var oldTranslation      : SIMD3<Float>? {
        willSet {
            if let newValue = newValue, let newTranslation = newTranslation {
                relativeTranslation = newValue - newTranslation
            }
        }
    }
    var newTranslation      : SIMD3<Float>? {
        didSet {
            if let oldValue = oldValue {
                oldTranslation = oldValue
            }
        }
    }
    var relativeTranslation : SIMD3<Float>?
    // Point of placing of model (relative to y-axis)
    var modelPlacementPoint : SIMD3<Float>?
    
    // init
    init(frame: CGRect, arSessionViewEvent: ARSessionViewEvent) {
        self.arSessionViewEvent = arSessionViewEvent
        super.init(frame: frame)
        
        self.setupView()
        self.setupConstrains()
    
        self.presentationMode = ARSessionViewPresentationMode.initial
        self.detectPlacementPointForTargetShape = false
        
        // setup gesture recognizers
        self.makeScreenUITapGestureRecognizers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            if !arView.subviews.contains(where: {type(of: $0) == ARCoachingOverlayView.self}) {
                self.arCoachingOverlayView = makeCoachingOverlayView(goal: .anyPlane)
                self.arView.addSubview(arCoachingOverlayView)
                arCoachingOverlayView.edgesToSuperview()
                self.arView.bringSubviewToFront(self.arCoachingOverlayView)
                self.arCoachingOverlayView.session = arSession
                self.arCoachingOverlayView.delegate = self
            }
        case .createSuccess(let modelEntity, let names):
            self.names = names
            self.placingModelEntity = modelEntity
            self.viewData = .initial
        }
    }
    
    // MARK: Action handlers
    /// Tap handler for an existing model to start editing it.
    /// - Parameter sender: UITapGestureRecognizer as sender.
    @objc func tapGestureRecognizerHandler (sender: UITapGestureRecognizer) {

        guard sender.view == self.arView else { fatalError()} // TODO: !! !

        let entities = (sender.view as! ARView).entities(at: sender.location(in: sender.view))
        if let parentEntity = entities.first as? ModelEntity,
           let anchorEntity = parentEntity.parent as? AnchorEntity,
           let modelEntity = parentEntity.children.first {
  
            self.anchorEntityEditable = anchorEntity

            let newTranslation = SIMD3<Float>(x: parentEntity.transform.translation.x,
                                              y: parentEntity.transform.translation.y + 0.10,
                                              z: parentEntity.transform.translation.z)
            let transform = Transform(scale: parentEntity.transform.scale, rotation: parentEntity.transform.rotation, translation: newTranslation)
           
            self.startEditingMoving = parentEntity.move(to: transform, relativeTo: anchorEntity, duration: 0.8, timingFunction: .easeIn)
            self.startEditingMovingComplete = self.arView.scene.publisher(for: AnimationEvents.PlaybackCompleted.self)
                .filter{$0.playbackController == self.startEditingMoving}
                .sink{ _ in
                    // overriding CollisionComponent
                    let entityBounds = modelEntity.visualBounds(relativeTo: parentEntity)
                    parentEntity.collision = self.makeEditingCollisionComponent(entityBounds: entityBounds)
                    // add gestures
                    self.arView.installGestures([.rotation, .scale], for: parentEntity)
                    
                    self.baseLevitationPoint = parentEntity.transform.translation
                    self.presentationMode = .editing
                    // gestures
                    self.makeScreenUIPanGestureRecognizers()
                    self.killUITapGestureRecognizers()
                    // levitation animation
                    self.makeLevitation(modelEntity: parentEntity)
                    
                    self.arView.debugOptions.insert(.showPhysics)
                }
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
        
        guard let modelEntity = self.placingModelEntity,
              let names = self.names else { return }
        
        // modelEntity naming
        modelEntity.name = names.modelEntityName
        
        // add parentEntiry
        let parentEntity = ModelEntity()
        parentEntity.name = names.parentEntityName
        parentEntity.addChild(modelEntity)
        
        // add collision to parentEntiry
        let entityBounds = modelEntity.visualBounds(relativeTo: parentEntity)
        parentEntity.collision = self.makeNormalCollisionComponent(entityBounds: entityBounds)
        
        // anchorEntity
        let anchorEntity = AnchorEntity(plane: .any)
        anchorEntity.name = names.anchorEntityName
        anchorEntity.addChild(parentEntity)
        
        // transformation
        // remember target dimensions of model
        self.finalPlacementTransformation = parentEntity.transform
        // zero out size of model for smooth appearance
        self.initialPlacementTransformation = Transform(scale: SIMD3<Float>(repeating: 0.00),
                                                        rotation: self.finalPlacementTransformation!.rotation,
                                                        translation: self.finalPlacementTransformation!.translation)
        parentEntity.transform = initialPlacementTransformation!
        
        // add to scene
        self.arView.scene.addAnchor(anchorEntity)
        
        parentEntity.move(to: finalPlacementTransformation!, relativeTo: anchorEntity, duration: 0.3, timingFunction: .easeIn)
        
        // zeroing of irrelevant variables
        self.placingModelEntity = nil
        self.initialPlacementTransformation = nil
        self.finalPlacementTransformation = nil
        
        self.viewData = .initial
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
        
        guard let anchorEntityEditable = self.anchorEntityEditable,
              let parentEntity = self.anchorEntityEditable!.children.first as? ModelEntity,
              let modelEntity = parentEntity.children.first
        else { return }

        let newTranslation = SIMD3<Float>(x: parentEntity.transform.translation.x,
                                          y: 0.00,
                                          z: parentEntity.transform.translation.z)
        
        let newTransformform = Transform(scale: parentEntity.transform.scale, rotation: parentEntity.transform.rotation, translation: newTranslation)
        
        self.killLevitation(modelEntity: parentEntity)
        self.endEditingMoving = parentEntity.move(to: newTransformform, relativeTo: anchorEntityEditable, duration: 0.8, timingFunction: .easeOut)
        self.endEditingMovingComplete = self.arView.scene.publisher(for: AnimationEvents.PlaybackCompleted.self)
            .filter{$0.playbackController == self.endEditingMoving}
            .sink{ _ in
                // overriding CollisionComponent
                let entityBounds = modelEntity.visualBounds(relativeTo: parentEntity)
                parentEntity.collision = self.makeNormalCollisionComponent(entityBounds: entityBounds)
                // Make UITapGestureRecognizer
                self.makeScreenUITapGestureRecognizers()
                self.killUIPanGestureRecognizers()
                
                // remove gestureRecognizers using filter RealityKit.EntityTranslationGestureRecognizer
                self.arView.gestureRecognizers?.removeAll(where: {type(of: $0) == RealityKit.EntityTranslationGestureRecognizer.self})
                
                self.anchorEntityEditable = nil
                self.baseLevitationPoint = nil
                self.presentationMode = .initial
                
                self.arView.debugOptions = []
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
                    // remove anchorEnity
                    self.arView.scene.anchors.remove(anchorEnity)
                    // installation of general gesture recognizers for view.
                    self.makeScreenUITapGestureRecognizers()
                    // clearing irrelevant values
                    self.deletingMoving = nil
                    self.deletingMovingcomplete?.cancel()
                    
                    self.presentationMode = .initial
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

extension ARSessionView : ARCoachingOverlayViewDelegate {

    public func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3) {
                self.targetShape?.isEnabled = false
            }
        }
    }
    
    public func coachingOverlayViewDidDeactivate (_ coachingOverlayView: ARCoachingOverlayView) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3) {
                self.targetShape?.isEnabled = true
            }
        }
    }
}
