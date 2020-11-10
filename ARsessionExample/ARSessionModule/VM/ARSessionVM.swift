//  ARSessionVM.swift
//  ARsessionExample
//  Created by Dmitry Samartcev on 10.11.2020.

import Foundation
import ARKit
import Combine

/// Class for ArSession view model delegate.
protocol ARSessionVMDelegate : class {
    
}

/// Class for ArSession view model protocol.
protocol ARSessionVM {
    var updateViewData: ((ARSessionData) -> ())? { get set }
    var delegate : ARSessionVMDelegate? { get set }
    func createAndRunARSession()
}

/// Class for ArSession view model implimentation.
final class ARSessionVMImplement : ARSessionVM {
    var updateViewData: ((ARSessionData) -> ())?
    var delegate: ARSessionVMDelegate?
    
    fileprivate var arSessionViewEvent: ARSessionViewEvent!
    fileprivate var arSessionViewEventSubscriber: AnyCancellable?
    
    // ArSession
    fileprivate var arSession : ARSession?
    fileprivate var arSessionConfiguration : ARWorldTrackingConfiguration?
    
    init(arSessionViewEvent: ARSessionViewEvent) {
        self.arSessionViewEvent = arSessionViewEvent
        subscribe()
    }
    
    func subscribe() {
        self.arSessionViewEventSubscriber = arSessionViewEvent.publisherRequest.sink{request in
            switch request {
            case .hello:
                print ("Say hello from ARSessionVMImplement")
            }
        }
    }
    
    func unsSubscribe() {
        self.arSessionViewEventSubscriber?.cancel()
    }
    
    func createAndRunARSession() {
        self.arSessionConfiguration = makeArSessionConfiguration()
        self.arSession = ARSession()
        self.arSession!.run(self.arSessionConfiguration!, options: [.removeExistingAnchors, .resetTracking])
        UIApplication.shared.isIdleTimerDisabled = true
        self.updateViewData?(.linkTo(arSession: self.arSession!))
    }

    fileprivate func makeArSessionConfiguration() -> ARWorldTrackingConfiguration {
        let arSessionConfiguration = ARWorldTrackingConfiguration()
        arSessionConfiguration.isCollaborationEnabled = true
        arSessionConfiguration.environmentTexturing = .automatic
        arSessionConfiguration.planeDetection = [.horizontal]
        return arSessionConfiguration
    }
}
