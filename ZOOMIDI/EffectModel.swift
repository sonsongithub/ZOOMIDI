//
//  EffectModel.swift
//  ZOOMIDI
//
//  Created by Yuichi Yoshida on 2023/07/17.
//

import Foundation
import SwiftUI

class EffectModel: ObservableObject {
    @Published var effects: [Effector] = []
    
    init() {
    }
    
    init(effects: [Effector]) {
        self.effects = effects
        NotificationCenter.default.addObserver(self, selector: #selector(doSomething(notification:)), name: .updatePatches, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(udpateValue(notification:)), name: .updateValue, object: nil)
    }
    
    @objc func doSomething(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let objs = userInfo["values"] as? [Effector] {
            self.effects = objs
        }
    }
    
    @objc func udpateValue(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Int] else { return }
        
        guard let effectNum = userInfo["effectNum"] else { return }
        guard let paramNum = userInfo["paramNum"] else { return }
        guard let value = userInfo["value"] else { return }
        
//        self.effects[effectNum].params[paramNum - 2] = value
        
    }
}
