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
        Text("a").frame(width: 100, height: 150).background()
    }
}

//switch item.type {
//case .single(name: _, default: _, max: _, offset: _):
//    Text("single = \(item.value)")
//default:
//    Text("other = \(item.value)")
//}
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
    static let effects: [Effector] = { () in
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
            let patch = try Patch(bytes: bytes)
            return patch.effects
        } catch {
            print(error)
        }
        return []
    }()
    
    static var previews: some View {
        ContentView(model: EffectModel(effects: effects))
    }
}
