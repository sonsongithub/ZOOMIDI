//
//  ContentView.swift
//  ZOOMIDI
//
//  Created by Yuichi Yoshida on 2023/07/17.
//

import SwiftUI

struct CABView: View {
    var text: String
    
    enum Note {
        case none
        case sixteenthNote
        case eighthNote
        case quarterNote
        case halfNote
        case wholeNote
    }
    
    var imageType: Note
    
    init(keyword: String) {
        let regrex = /&#x([\w\d]+);\s*(.*?)/
        if let match = keyword.wholeMatch(of: regrex) {
            text = String(match.output.2)
            switch match.output.1 {
            case "1D15D":
                imageType = .wholeNote
            case "1D15E":
                imageType = .halfNote
            case "1D15F":
                imageType = .quarterNote
            case "1D160":
                imageType = .eighthNote
            case "1D161":
                imageType = .sixteenthNote
            default:
                print(keyword)
                imageType = .none
            }
        } else {
            imageType = .none
            text = keyword
        }
    }
    
    var body: some View {
        HStack {
            switch imageType {
            case .sixteenthNote:
                Image("sixteenth_note")
            case .eighthNote:
                Image("eighth_note")
            case .quarterNote:
                Image("quarter_note")
            case .halfNote:
                Image("half_note")
            case .wholeNote:
                Image("whole_note")
            default:
                do {}
            }
            Text(self.text)
        }
    }
}

struct HogeView: View {
    
    @ObservedObject var parameter: Parameter
    let gradient = Gradient(colors: [.gray, .black])
    
    var body: some View {
        switch parameter.type {
        case .single(let name, _, let max, let offset):
            VStack {
                Text(name)
                Gauge(value: parameter.floatValue + Float(offset), in:  Float(offset)...Float(max) + Float(offset)) {
//                    Text("\(name)")
                } currentValueLabel: {
                    Text("\(Int(parameter.floatValue + Float(offset)))")
                }.gaugeStyle(.accessoryCircular)
                Slider(value: $parameter.floatValue, in: 0...Float(max), step: 1) {
                }.onChange(of: parameter.floatValue) { newValue in
                    let userInfo: [String: Any] = [
                        "parameter": Int(parameter.floatValue),
                        "UUID": parameter.id
                    ]
                    NotificationCenter.default.post(name: .updateParameter, object: nil, userInfo: userInfo)
                }

            }.frame(width: 100, height:180).background()
        case .list(let name, _, let _, let titles):
            VStack {
                Text(name)
                Picker(selection: $parameter.intValue, label: Text(name)) {
                    ForEach(0..<Int(titles.count)) { i in
                        Text(titles[i])
                    }
                }.onChange(of: parameter.intValue) { newValue in
                    print(newValue)
                    let userInfo: [String: Any] = [
                        "parameter": Int(parameter.intValue),
                        "UUID": parameter.id
                    ]
                    NotificationCenter.default.post(name: .updateParameter, object: nil, userInfo: userInfo)
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
                    let userInfo: [String: Any] = [
                        "parameter": Int(parameter.intValue),
                        "UUID": parameter.id
                    ]
                    NotificationCenter.default.post(name: .updateParameter, object: nil, userInfo: userInfo)
                }
            }.frame(width: 100, height:180).background()
        case .cab(let name, _, let max, _, _, let disp_min, let titles):
            VStack {
                Text(name)
                Gauge(value: parameter.floatValue, in: 0...Float(max)) {
                } currentValueLabel: {
                    if parameter.floatValue > Float(max - titles.count) {
                        CABView(keyword: titles[Int(parameter.floatValue - Float(max - titles.count))-1])
                    } else {
                        Text("\(Int(parameter.floatValue) + disp_min)")
                    }
                }.gaugeStyle(.accessoryCircular)
                Slider(value: $parameter.floatValue, in: 0...Float(max), step: 1) {
                }.onChange(of: parameter.floatValue) { newValue in
                    print(newValue)
                    let userInfo: [String: Any] = [
                        "parameter": Int(parameter.floatValue),
                        "UUID": parameter.id
                    ]
                    NotificationCenter.default.post(name: .updateParameter, object: nil, userInfo: userInfo)
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
                Text(String(effect.type.name.replacing([" "], with: ["_"])))
                Image(effect.type.name.replacing([" "], with: ["_"]))
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
