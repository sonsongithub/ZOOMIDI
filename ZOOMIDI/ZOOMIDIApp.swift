//
//  ZOOMIDIApp.swift
//  ZOOMIDI
//
//  Created by Yuichi Yoshida on 2023/07/17.
//

import SwiftUI

@main
struct ZOOMIDIApp: App {
    
    @StateObject var patch = Patch()
    
    var midiManger = MIDIManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView(patch: patch)
                .task {
                    midiManger.start()
                }
        }
    }
}
