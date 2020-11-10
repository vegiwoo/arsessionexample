//
//  ModulesBuilder.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.
//

import UIKit

final class ModulesBuilder {
    static func createArSessionModule() -> UIViewController? {
        let arSessionViewEvent = ARSessionViewEvent()
        let vm = ARSessionVMImplement(arSessionViewEvent: arSessionViewEvent)
        return ARSessionVC(vm: vm, arSessionViewEvent: arSessionViewEvent)
    }
    
    static func createArSessionSettingsModule(options : [ARSessionSettingsOptions]) -> UIViewController? {
        let arSessionSettingsViewEvent = ARSessionSettingsViewEvent()
        let vm = ARSessionSettingsVMImplement(options: options, arSessionSettingsViewEvent: arSessionSettingsViewEvent)
        return ARSessionSettingsVC(vm: vm, arSessionSettingsViewEvent: arSessionSettingsViewEvent)
    }
}
