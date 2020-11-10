//  ARSessionView.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.

import UIKit
import RealityKit
import Combine

/// Class for the ArSession view
class ARSessionView : UIView {
    
    var viewData: ARSessionData = .initial {
        didSet {
            self.setNeedsLayout()
        }
    }
    
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
        self.addTargets()
        
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
        }
    }

    fileprivate func addTargets() {
        
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
