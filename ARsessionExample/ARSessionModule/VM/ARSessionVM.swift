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
    func gettingCurrentSettingsFromARSession() -> [ARSessionSettingsOptions]
    func receivingNewSettingsForARSession(options: ARSessionSettingsOptions)
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
    
    func gettingCurrentSettingsFromARSession() -> [ARSessionSettingsOptions] {
 
        var currentOptions = [ARSessionSettingsOptions]()
        guard let configuration = self.arSession?.configuration as? ARWorldTrackingConfiguration  else { fatalError()}
        // Getting planeDetection settings
        let planeDetection = configuration.planeDetection
        
        let detectAllPlanesImage = UIImage(named: "icon_planeDetect_all")?.withRenderingMode(.alwaysTemplate)
        let detectAllPlanes = ARSessionSettingsOptions.init(key: ARSessionSettingsOptionsKeys.detectAllPlanes, group: ARSessionSettingsOptionsGroup.planeDetectionMode, image: detectAllPlanesImage, isSelected: false)
        let detectVerticalPlanesOnlyImage = UIImage(named: "icon_planeDetect_vertical")?.withRenderingMode(.alwaysTemplate)
        let detectVerticalPlanesOnly = ARSessionSettingsOptions.init(key: ARSessionSettingsOptionsKeys.detectVerticalPlanesOnly, group: ARSessionSettingsOptionsGroup.planeDetectionMode, image: detectVerticalPlanesOnlyImage, isSelected: false)
        let detectHorizontalPlanesOnlImage = UIImage(named: "icon_planeDetect_horizont")?.withRenderingMode(.alwaysTemplate)
        let detectHorizontalPlanesOnly = ARSessionSettingsOptions.init(key: ARSessionSettingsOptionsKeys.detectHorizontalPlanesOnly, group: ARSessionSettingsOptionsGroup.planeDetectionMode, image: detectHorizontalPlanesOnlImage, isSelected: false)
        let turnOffPlaneDetectionImage = UIImage(named: "icon_planeDetect_none")?.withRenderingMode(.alwaysTemplate)
        let turnOffPlaneDetection = ARSessionSettingsOptions.init(key: ARSessionSettingsOptionsKeys.turnOffPlaneDetection, group: ARSessionSettingsOptionsGroup.planeDetectionMode, image: turnOffPlaneDetectionImage, isSelected: false)
        
        if planeDetection.contains([.horizontal, .vertical]) {
            detectAllPlanes.isSelected = true
        }
        if planeDetection.contains([.vertical]), !planeDetection.contains([.horizontal]) {
            detectVerticalPlanesOnly.isSelected = true
        }
        if planeDetection.contains([.horizontal]), !planeDetection.contains([.vertical]) {
            detectHorizontalPlanesOnly.isSelected = true
        }
        if !planeDetection.contains([.horizontal]), !planeDetection.contains([.vertical]) {
            turnOffPlaneDetection.isSelected = true
        }
        currentOptions.append(contentsOf: [detectAllPlanes, detectVerticalPlanesOnly, detectHorizontalPlanesOnly, turnOffPlaneDetection])
        
        return currentOptions
    }
    
    func receivingNewSettingsForARSession(options: ARSessionSettingsOptions) {
        switch options.group {
        case .planeDetectionMode:
            if options.name == ARSessionSettingsOptionsKeys.detectAllPlanes.name {
                // Go detectAllPlanes
            } else if options.name == ARSessionSettingsOptionsKeys.detectHorizontalPlanesOnly.name{
                // Go detectHorizontalPlanesOnly
            } else if options.name == ARSessionSettingsOptionsKeys.detectVerticalPlanesOnly.name  {
                // Go detectVerticalPlanesOnly
            } else if options.name == ARSessionSettingsOptionsKeys.turnOffPlaneDetection.name  {
                // Go turnOffPlaneDetection
            }
        }
    }
}
