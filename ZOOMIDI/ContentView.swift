//
//  ContentView.swift
//  ZOOMIDI
//
//  Created by Yuichi Yoshida on 2023/07/17.
//

import SwiftUI

struct EffectView: View {
    @ObservedObject var effect: Effect
    
    var body: some View {
        VStack {
            HStack {
                Text(String(effect.name))
                Image(effect.name)
            }
            ForEach(effect.params.filter({ $0.template is EffectSingleParam })) { item in
                 VStack {
                    Text(item.template.name)
                    Gauge(value: Float(item.value)) {
                    } currentValueLabel: {
                        Text("\(Float(item.value))")
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("\((item.template as! EffectSingleParam).max)")
                    }
                    .gaugeStyle(.accessoryCircular)
                }
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var model: EffectModel
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(self.model.effects.reversed()) { item in
                    EffectView(effect: item)
                        .frame(width: 400, height: 600)
                        .background(.gray)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static let effects: [Effect] = { () in
        EffectData.load()
        let manager = MIDIManager()
        guard let path = Bundle.main.path(forResource: "patchData01.bin", ofType: nil) else { return [] }
        do {
            let url = URL(filePath: path)
            let data = try Data(contentsOf: url)
            let bytes = data.withUnsafeBytes { pointer in
                let p = pointer.bindMemory(to: UInt8.self)
                return [UInt8](UnsafeBufferPointer(start: p.baseAddress, count: data.count))
            }
            return try manager.parsePatchBytes(bytes: bytes)
        } catch {
            print(error)
            return []
        }
    }()
    
    static var previews: some View {
        ContentView(model: EffectModel(effects: effects))
    }
}
