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
    lazy var arView : CustomARView = self.makeArView()
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
    
    var placingModelEntity : ThreeDModelEntity? {
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
    var startEditingMoving: AnimationPlaybackController!
    var startEditingMovingComplete: AnyCancellable?
    var endEditingMoving : AnimationPlaybackController!
    var endEditingMovingComplete : AnyCancellable?
    
    // target shape
    var detectPlacementPointForTargetShape: Bool! {
        didSet {
            if detectPlacementPointForTargetShape == false {
                //self.deleteteTargetShape()
            }
        }
    }
    var targetShapeWorldTransform : simd_float4x4? {
        willSet {
            if let newValue = newValue {
                //self.changesToTargetShape(transform: newValue)
            }
        }
    }
    //var targetShape : AnchorEntity?
    //var deletingTargetShapeMoving: AnimationPlaybackController!
    //var deletingTargetShapeMovingComplete : AnyCancellable?

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
    // Точка установки модели относительно оси y
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
            self.arCoachingOverlayView = makeCoachingOverlayView(goal: .anyPlane)
            self.arView.addSubview(arCoachingOverlayView)
            arCoachingOverlayView.edgesToSuperview()
            self.arView.bringSubviewToFront(self.arCoachingOverlayView)
            self.arCoachingOverlayView.session = arSession
            self.arCoachingOverlayView.delegate = self
        case .createSuccess(let threeDModelEntity):
            if self.placingModelEntity == nil {
                self.placingModelEntity = threeDModelEntity
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
           let anchorEntity = parentEntity.parent as? AnchorEntity {
  
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
                    parentEntity.collision = CollisionComponent(shapes: [ShapeResource.generateSphere(radius: 3.0)])
                    // add gestures
                    self.arView.installGestures([.rotation, .scale], for: parentEntity)
                    
                    self.baseLevitationPoint = parentEntity.transform.translation
                    self.presentationMode = .editing
                    // gestures
                    self.makeScreenUIPanGestureRecognizers()
                    self.killUITapGestureRecognizers()
                    // levitation animation
                    self.makeLevitation(modelEntity: parentEntity)
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
        if let placingModelEntity = self.placingModelEntity {

            self.arView.scene.addAnchor(placingModelEntity.anchorEntity!)

            placingModelEntity.parentEntity!.move(to: placingModelEntity.finalPlacementTransformation!, relativeTo: placingModelEntity.anchorEntity!, duration: 0.3, timingFunction: .easeIn)
            
            self.placingModelEntity = nil
            self.viewData = .initial
            
            self.arView.debugOptions.insert(.showPhysics)
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
           let parentEntity = self.anchorEntityEditable!.children.first as? ModelEntity,
           let modelEntity = parentEntity.children.first as? ModelEntity{
            
            let newTranslation = SIMD3<Float>(x: parentEntity.transform.translation.x,
                                              y: 0.00,
                                              z: parentEntity.transform.translation.z)

            let newTransformform = Transform(scale: parentEntity.transform.scale, rotation: parentEntity.transform.rotation, translation: newTranslation)

            self.killLevitation(modelEntity: parentEntity)
            self.endEditingMoving = parentEntity.move(to: newTransformform, relativeTo: anchorEntityEditable!, duration: 0.8, timingFunction: .easeInOut)
            self.endEditingMovingComplete = self.arView.scene.publisher(for: AnimationEvents.PlaybackCompleted.self)
                .filter{$0.playbackController == self.endEditingMoving}
                .sink{ _ in
                    // overriding CollisionComponent
                    let entityBounds = modelEntity.visualBounds(relativeTo: parentEntity)
                    parentEntity.collision = CollisionComponent(shapes: [ShapeResource.generateBox(size: entityBounds.max).offsetBy(translation: entityBounds.center)])
                    // Make UITapGestureRecognizer
                    self.makeScreenUITapGestureRecognizers()
                    self.killUIPanGestureRecognizers()
                    
                    // remove gestureRecognizers using filter RealityKit.EntityTranslationGestureRecognizer
                    self.arView.gestureRecognizers?.removeAll(where: {type(of: $0) == RealityKit.EntityTranslationGestureRecognizer.self})
                    
                    self.anchorEntityEditable = nil
                    self.baseLevitationPoint = nil
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
                self.arView.focusEntity.isEnabled = false
            }
        }
    }
    
    public func coachingOverlayViewDidDeactivate (_ coachingOverlayView: ARCoachingOverlayView) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3) {
                self.arView.focusEntity.isEnabled = true
            }
        }
        
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
        // create FocusEntity
        let meshResource = MeshResource.generatePlane(width: 0.3, depth: 0.3)
        var texture: TextureResource?
        var material: UnlitMaterial!
        do {
            if let textureURL = Bundle.main.url(forResource: "targetShapeTexture_001", withExtension: "png") {
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
        
        let modelEntity = ModelEntity(mesh: meshResource, materials: [material])
        focusEntity = FocusEntity(on: self, style: .classic(color: UIColor.clear))
        focusEntity.addChild(modelEntity)
        
        self.focusEntity.delegate = self
        self.focusEntity.setAutoUpdate(to: true)
        self.focusEntity.isEnabled = true
    }
    
    @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
