//
//  Effect.swift
//  ZOOMIDI
//
//  Created by Yuichi Yoshida on 2023/07/17.
//

import Foundation
import SwiftUI

class Parameter: ObservableObject, Identifiable {
    var id: UUID
    @Published var value: Int
    
    let template: any EffectParameter
    
    init(value: Int, template: any EffectParameter) {
        self.id = UUID()
        self.value = value
        self.template = template
    }
}

class Effect: ObservableObject, Identifiable {
    let name: String
    let group: String
    let order: Int
    let install: Int
    let version: Int
    let title: String
    let dsp: Float
    let dspMax: Float
    let dspMin: Float
    @Published var id: UUID
    @Published var effectId: Int
    @Published var status: Int
    @Published var params: [Parameter]
    
    init(template: EffectData, effectId: Int, status: Int, values: [Int], params: [any EffectParameter]) {
        self.name = template.name
        self.group = template.group
        self.order = template.order
        self.install = template.install
        self.version = template.version
        self.title = template.title
        self.dsp = template.dsp
        self.dspMax = template.dspMax
        self.dspMin = template.dspMin
        self.id = UUID()
        self.effectId = effectId
        self.status = status
        
        let count = params.count
        let tmpValues = values[0..<count]

        self.params = zip(params, tmpValues).map({ (template, value) in
            return Parameter(value: value, template: template)
        })
    }
    
    
}

