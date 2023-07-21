//
//  ZOOMIDIApp.swift
//  ZOOMIDI
//
//  Created by Yuichi Yoshida on 2023/07/17.
//

import SwiftUI

@main
struct ZOOMIDIApp: App {
    static let effects: [Effect] = [
//            Effect(effectId: 0, status: 1, params: [0, 1, 2]),
//            Effect(effectId: 2, status: 1, params: [2, 1, 2]),
//            Effect(effectId:10, status: 1, params: [3, 1, 2]),
        ]
    
    @StateObject var model = EffectModel(effects: ZOOMIDIApp.effects)
    
    var midiManger = MIDIManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .task {
                    EffectData.load()
                    midiManger.start()
                }
        }
    }
}
