//
//  Parameter.swift
//  ZOOMIDI
//
//  Created by Yuichi Yoshida on 2023/07/22.
//

import Foundation
import SwiftUI

class Parameter: ObservableObject, Identifiable {
    let id: UUID
    @Published var value: Float
    @Published var floatValue: Float
    @Published var intValue: Int
    
    let type: ParameterType
    
    init(value: Int, type: ParameterType) {
        self.id = UUID()
        self.value = Float(value)
        self.floatValue = Float(value)
        self.intValue = value
        self.type = type
    }
}
