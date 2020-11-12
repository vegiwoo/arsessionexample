//  ARSessionView.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.

import UIKit
import ARKit
import RealityKit
import Combine


/// Class for the ArSession view
class ARSessionView : UIView {
    
    var viewData: ARSessionData = .initial {
        didSet {
            self.setNeedsLayout()
        }
    }
    var arCoachingOverlayView : ARCoachingOverlayView!
    private var arSessionViewEvent : ARSessionViewEvent!
    
    // UI cotrols
    lazy var arView : ARView = self.makeArView()
    lazy var settingsButton : UIButton = makeFunctionalButton(sfSymbolName: "gear")
    
    lazy var functionalButtonsStack : UIStackView = makeFunctionalButtonsStack()
    
    init(frame: CGRect, arSessionViewEvent: ARSessionViewEvent) {
        self.arSessionViewEvent = arSessionViewEvent
        super.init(frame: frame)
        
        self.setupView()
        self.setupConstrains()
        
        self.viewData = .initial
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        switch viewData {
        case .initial:
            break
        case .linkTo(arSession: let arSession):
            self.arView.session = arSession
            
            self.arCoachingOverlayView = makeCoachingOverlayView(goal: .anyPlane)
            self.arView.addSubview(arCoachingOverlayView)
            arCoachingOverlayView.edgesToSuperview()
            self.arView.bringSubviewToFront(self.arCoachingOverlayView)
            self.arCoachingOverlayView.session = arSession
            self.arCoachingOverlayView.delegate = self.arView
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
    case hello
}

extension ARView : ARCoachingOverlayViewDelegate {

    public func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        print(coachingOverlayViewDidRequestSessionReset)
    }
    
    
    public func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        print("coachingOverlayViewWillActivate")
    }
    
    
    public func coachingOverlayViewDidDeactivate (_ coachingOverlayView: ARCoachingOverlayView) {
        print("coachingOverlayViewDidDeactivate")
    }
}

