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
    
    var anchorEntityEditableTransform : Transform?
    var anchorEntityEditableTranslation : SIMD3<Float>?
    
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
    
    @objc func tapGestureRecognizerHandler (sender: UITapGestureRecognizer) {

        guard sender.view == self.arView else { fatalError()} // TODO: !! !

        let entities = (sender.view as! CustomARView).entities(at: sender.location(in: sender.view))
        if let parentEntity = entities.first as? ModelEntity,
          // let modelEntity = parentEntity.children.first as? ModelEntity,
           let anchorEntity = parentEntity.parent as? AnchorEntity {
  
            self.anchorEntityEditableTransform = parentEntity.transform
            
            let newTranslation = SIMD3<Float>(x: anchorEntityEditableTransform!.translation.x,
                                              y: anchorEntityEditableTransform!.translation.y + 0.10,
                                              z: anchorEntityEditableTransform!.translation.z)
            let transform = Transform(scale: anchorEntityEditableTransform!.scale, rotation: anchorEntityEditableTransform!.rotation, translation: newTranslation)
           
            parentEntity.move(to: transform, relativeTo: parentEntity, duration: 1.0, timingFunction: .default)
            
           // anchorEntity.move(to: transform, relativeTo: anchorEntity, duration: 0.5, timingFunction: .easeIn)
            self.arView.installGestures(for: parentEntity)
            
            self.presentationMode = .editing
        }
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
    
    // Button handlers
    @objc func modelButtonTapHandler(sender: UIButton) {
        self.arSessionViewEvent.publish(request: .createModelEntityFromFile)
        
    }
    @objc func settingsButtonTapHandler(sender: UIButton) {
        self.arSessionViewEvent.publish(request: .showSettingsPage)
    }
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
            //self.arView.installGestures([.all], for: parentEntity)
            self.arView.scene.addAnchor(anchorEntity)

            self.placingModelEntity = nil
            self.viewData = .initial
        }
    }
    @objc func cancelButtonPlacing (sender: UIButton) {
        self.placingModelEntity = nil
        self.viewData = .initial
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
