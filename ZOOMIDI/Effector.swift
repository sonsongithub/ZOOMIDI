//
//  Effect.swift
//  ZOOMIDI
//
//  Created by Yuichi Yoshida on 2023/07/17.
//

import Foundation
import SwiftUI

class Parameter: ObservableObject, Identifiable {
    let id: UUID
    @Published var value: Int
    
    let type: ParameterType
    
    init(value: Int, type: ParameterType) {
        self.id = UUID()
        self.value = value
        self.type = type
    }
}

class Effector: ObservableObject, Identifiable {
    let type: EffectorType
    let id: UUID
    @Published var status: Int
    @Published var params: [Parameter]
    
    init(type: EffectorType, status: Int, parameters: [Parameter]) {
        self.type = type
        self.id = UUID()
        self.status = status
        self.params = parameters
    }
}

