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
    let cab: Int
    @Published var status: Int
    @Published var params: [Parameter]
    
    init(type: EffectorType, status: Int, cab: Int, parameters: [Parameter]) {
        self.type = type
        self.id = UUID()
        self.status = status
        self.params = parameters
        self.cab = cab
    }
    
    init(type: EffectorType) {
        self.type = type
        self.id = UUID()
        self.status = 1
        self.cab = 0
        
        let temp: [Parameter?] = type.parameters.map({
            switch $0 {
            case .single(_, let defaultValue, _, _):
                return Parameter(value: defaultValue, type: $0)
            case .cab(_, let defaultValue, _, _):
                return Parameter(value: defaultValue, type: $0)
            case .list(_, let defaultValue, _, _):
                return Parameter(value: defaultValue, type: $0)
            case .pair(_, let defaultValue, _, _, _, _, _):
                return Parameter(value: defaultValue, type: $0)
            default:
                return nil
            }
        })
        self.params = temp.compactMap({ $0 })
    }
}

