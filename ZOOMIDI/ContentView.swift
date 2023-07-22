//
//  ContentView.swift
//  ZOOMIDI
//
//  Created by Yuichi Yoshida on 2023/07/17.
//

import SwiftUI

struct HogeView: View {
    
    @ObservedObject var parameter: Parameter
    
    var body: some View {
        switch parameter.type {
        case .single(let name, _, let max, _):
            VStack {
                Text(name)
                Gauge(value: parameter.floatValue) {
                    Text("\(name)")
                } currentValueLabel: {
                    Text("\(Int(parameter.floatValue))")
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("\(max)")
                }.gaugeStyle(.accessoryCircular)
                Slider(value: $parameter.floatValue, in: 0...Float(max), step: 1) {
                }.onChange(of: parameter.floatValue) { newValue in
                    print(newValue)
                }

            }.frame(width: 100, height:180).background()
        case .list(let name, _, let _, let titles):
            VStack {
                Text(name)
                Picker(selection: $parameter.intValue, label: Text(name)) {
                    ForEach(0..<titles.count) { i in
                        Text(titles[i])
                    }
                }.onChange(of: parameter.intValue) { newValue in
                    print(newValue)
                }
            }.frame(width: 100, height:180).background()
        case .pair(let name, _, let max, let titles):
            VStack {
                Text(name)
                Picker(selection: $parameter.intValue, label: Text(name)) {
                    ForEach(0..<titles.count) { i in
                        Text(titles[i])
                    }
                }.onChange(of: parameter.intValue) { newValue in
                    print(max[newValue])
                }
            }.frame(width: 100, height:180).background()
        case .none:
            VStack {
                Text("")
            }.frame(width: 100, height:180).background(.clear)
        default:
            VStack {
                Text("\(parameter.value)")
            }.frame(width: 100, height:180).background()
        }
    }
}


struct EffectView: View {
    @ObservedObject var effect: Effector
    
    var body: some View {
        VStack {
            HStack {
                Text(String(effect.type.name))
                Image(effect.type.name)
            }
             VStack {
                 HStack {
                     HogeView(parameter: effect.params[0])
                     HogeView(parameter: effect.params[1])
                     HogeView(parameter: effect.params[2])
                 }
                 HStack {
                     HogeView(parameter: effect.params[3])
                     HogeView(parameter: effect.params[4])
                     HogeView(parameter: effect.params[5])
                 }
                 HStack {
                     HogeView(parameter: effect.params[6])
                     HogeView(parameter: effect.params[7])
                     HogeView(parameter: effect.params[8])
                 }
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var patch: Patch
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(self.patch.effects.reversed()) { item in
                    EffectView(effect: item)
                        .frame(width: 400, height: 800)
                        .background(.gray)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static let patch: Patch = { () in
        do {
            try EffectorType.load()
            try PatchBinaryMap.load()
            guard let path = Bundle.main.path(forResource: "patchData01.bin", ofType: nil) else { throw NSError() }
            
            let url = URL(filePath: path)
            let data = try Data(contentsOf: url)
            let bytes = data.withUnsafeBytes { pointer in
                let p = pointer.bindMemory(to: UInt8.self)
                return [UInt8](UnsafeBufferPointer(start: p.baseAddress, count: data.count))
            }
            return try Patch(bytes: bytes)
        } catch {
            print(error)
            return Patch()
        }
    }()
    
    static var previews: some View {
        ContentView(patch: patch)
    }
}
