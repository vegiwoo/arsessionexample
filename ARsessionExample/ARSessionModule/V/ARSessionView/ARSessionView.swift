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
    
    init(frame: CGRect, arSessionViewEvent: ARSessionViewEvent) {
        self.arSessionViewEvent = arSessionViewEvent
        super.init(frame: frame)
        
        self.setupView()
        self.setupConstrains()
        self.addGestures()
        
        self.presentationMode = ARSessionViewPresentationMode.initial
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

        let entities = (sender.view as! CustomARView).entities(at: sender.location(in: sender.view))
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

extension CustomARView : ARCoachingOverlayViewDelegate {

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
    
    var meshResource : MeshResource!

    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        focusEntity = FocusEntity(on: self, style: .classic)
        focusEntity.delegate = self
        focusEntity.setAutoUpdate(to: true)
    }
    
    @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
