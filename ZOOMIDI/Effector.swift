//
//  Effect.swift
//  ZOOMIDI
//
//  Created by Yuichi Yoshida on 2023/07/17.
//

import Foundation
import SwiftUI

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
    
//    init(type: EffectorType) {
//        self.type = type
//        self.id = UUID()
//        self.status = 1
//        
//        self.type.parameters[0].
//    }
}

