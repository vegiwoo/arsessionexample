//
//  ARSessionVM.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.
//

import Foundation
import Combine


protocol ARSessionVMDelegate : class {
    
}

protocol ARSessionVM {
    var updateViewData: ((ARSessionData) -> ())? { get set }
    var delegate : ARSessionVMDelegate? { get set }
}

final class ARSessionVMImplement : ARSessionVM {
    var updateViewData: ((ARSessionData) -> ())?
    var delegate: ARSessionVMDelegate?
    
    fileprivate var arSessionViewEvent: ARSessionViewEvent!
    fileprivate var arSessionViewEventSubscriber: AnyCancellable?
    
    init(arSessionViewEvent: ARSessionViewEvent) {
        self.arSessionViewEvent = arSessionViewEvent
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
    
    
}
