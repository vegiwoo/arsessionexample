//  ARSessionVM.swift
//  ARsessionExample
//  Created by Dmitry Samartcev on 10.11.2020.

import Foundation
import ARKit
import Combine
import PromiseKit

/// Class for ArSession view model delegate.
protocol ARSessionVMDelegate : class {
    // ...
}

/// Class for ArSession view model protocol.
protocol ARSessionVM {
    var updateViewData: ((ARSessionData) -> ())? { get set }
    var delegate : ARSessionVMDelegate? { get set }
    var arSessionVMEvent : ARSessionVMEvent! { get set }
    func createAndRunARSession()
    func gettingCurrentSettingsFromARSession() -> [ARSessionSettingsOptions]
    func receivingNewSettingsForARSession(option: ARSessionSettingsOptions)
}

/// Class for ArSession view model implimentation.
final class ARSessionVMImplement : NSObject, ARSessionVM {
 
    var updateViewData: ((ARSessionData) -> ())?
    var delegate: ARSessionVMDelegate?
    
    
    // ArSession
    fileprivate var arSession : ARSession?
    fileprivate var arSessionConfiguration : ARWorldTrackingConfiguration?
    
    // Publishers && subscribers
    fileprivate var arSessionViewEvent: ARSessionViewEvent!
    fileprivate var arSessionViewEventSubscriber: AnyCancellable?
    var arSessionVMEvent : ARSessionVMEvent!
    
    init(arSessionViewEvent: ARSessionViewEvent) {
        self.arSessionViewEvent = arSessionViewEvent
        self.arSessionVMEvent = ARSessionVMEvent()
        super.init()
        
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
    
    fileprivate func makeArSessionConfiguration() -> ARWorldTrackingConfiguration {
        let arSessionConfiguration = ARWorldTrackingConfiguration()
        arSessionConfiguration.isCollaborationEnabled = true
        arSessionConfiguration.environmentTexturing = .automatic
        arSessionConfiguration.planeDetection = [.horizontal]
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            arSessionConfiguration.sceneReconstruction = .mesh
        }
        return arSessionConfiguration
    }
    
    func createAndRunARSession() {
        self.arSessionConfiguration = makeArSessionConfiguration()
        self.arSession = ARSession()
        self.arSession!.run(self.arSessionConfiguration!, options: [.removeExistingAnchors, .resetTracking])
        UIApplication.shared.isIdleTimerDisabled = true
        self.arSession?.delegate = self
        self.updateViewData?(.linkTo(arSession: self.arSession!))
    }

    func createARSessionSettingsOptions(group: ARSessionSettingsOptionsGroup) -> [ARSessionSettingsOptions]{
        switch group {
        case .planeDetectionMode:
            var planeDetectionModeOptions = [ARSessionSettingsOptions]()
            let detectAllPlanesImage = UIImage(named: "icon_planeDetect_all")?.withRenderingMode(.alwaysTemplate)
            let detectAllPlanes = ARSessionSettingsOptions.init(key: ARSessionSettingsOptionsKeys.detectAllPlanes, group: ARSessionSettingsOptionsGroup.planeDetectionMode, image: detectAllPlanesImage, isSelected: false)
            let detectVerticalPlanesOnlyImage = UIImage(named: "icon_planeDetect_vertical")?.withRenderingMode(.alwaysTemplate)
            let detectVerticalPlanesOnly = ARSessionSettingsOptions.init(key: ARSessionSettingsOptionsKeys.detectVerticalPlanesOnly, group: ARSessionSettingsOptionsGroup.planeDetectionMode, image: detectVerticalPlanesOnlyImage, isSelected: false)
            let detectHorizontalPlanesOnlImage = UIImage(named: "icon_planeDetect_horizont")?.withRenderingMode(.alwaysTemplate)
            let detectHorizontalPlanesOnly = ARSessionSettingsOptions.init(key: ARSessionSettingsOptionsKeys.detectHorizontalPlanesOnly, group: ARSessionSettingsOptionsGroup.planeDetectionMode, image: detectHorizontalPlanesOnlImage, isSelected: false)
            let turnOffPlaneDetectionImage = UIImage(named: "icon_planeDetect_none")?.withRenderingMode(.alwaysTemplate)
            let turnOffPlaneDetection = ARSessionSettingsOptions.init(key: ARSessionSettingsOptionsKeys.turnOffPlaneDetection, group: ARSessionSettingsOptionsGroup.planeDetectionMode, image: turnOffPlaneDetectionImage, isSelected: false)
            planeDetectionModeOptions.append(contentsOf: [detectAllPlanes,detectVerticalPlanesOnly,detectHorizontalPlanesOnly, turnOffPlaneDetection])
            return planeDetectionModeOptions
        }
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
    
    fileprivate func reconfigureSession(configuration: ARWorldTrackingConfiguration?) {
        if let session = self.arSession, let configuration = configuration {
            session.run(configuration, options: [])
        }
    }
    
    func receivingNewSettingsForARSession(option: ARSessionSettingsOptions) {

        let configuration = ARWorldTrackingConfiguration()
        
        switch option.group {
        case .planeDetectionMode:
            
            let options = self.createARSessionSettingsOptions(group: option.group)
            
            if option.name == ARSessionSettingsOptionsKeys.detectAllPlanes.name {
                configuration.planeDetection = [.horizontal, .vertical]
                options.first(where: {$0.name == option.name})?.isSelected = true
            } else if option.name == ARSessionSettingsOptionsKeys.detectHorizontalPlanesOnly.name{
                configuration.planeDetection = [.horizontal]
                options.first(where: {$0.name == option.name})?.isSelected = true
            } else if option.name == ARSessionSettingsOptionsKeys.detectVerticalPlanesOnly.name  {
                configuration.planeDetection = [.vertical]
                options.first(where: {$0.name == option.name})?.isSelected = true
            } else if option.name == ARSessionSettingsOptionsKeys.turnOffPlaneDetection.name  {
                configuration.planeDetection = []
                options.first(where: {$0.name == option.name})?.isSelected = true
            }
            self.arSessionVMEvent.publish(request: .returnNewOptions(options: options))
            self.reconfigureSession(configuration: configuration)
        }
    }
}
class ARSessionVMEvent {
    var publisherRequest: AnyPublisher<ARSessionVMEventInfo, Never> {
        subjectRequest.eraseToAnyPublisher()
    }
    
    private let subjectRequest = PassthroughSubject<ARSessionVMEventInfo, Never>()
    
    private(set) var request : ARSessionVMEventInfo? = nil {
        didSet {
            if let request = request {
                subjectRequest.send (request)
            }
        }
    }
    
    func publish(request: ARSessionVMEventInfo) {
        self.request = request
    }
}

enum ARSessionVMEventInfo {
    case returnNewOptions(options: [ARSessionSettingsOptions])
}

extension ARSessionVMImplement : ARSessionDelegate {

}
