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
    var lock: Bool = false
    @Published var value: Float
    @Published var floatValue: Float
    @Published var intValue: Int {
        didSet {
            switch type {
            case .cab(_, _, let max, let titles):
                print("intValue=\(intValue)")
                print(titles)
                print(max)
                if let temp = max.firstIndex(of: self.intValue) {
                    self.cabValue = temp
                } else {
                    self.cabValue = 0
                }
            default:
                do {}
            }
            print(self.cabValue)
        }
    }
    @Published var cabValue: Int
    
    let type: ParameterType
    
    init(value: Int, type: ParameterType) {
        self.id = UUID()
        self.value = Float(value)
        self.floatValue = Float(value)
        self.intValue = value
        self.type = type
        self.cabValue = 0
        
        switch type {
        case .cab(_, _, let max, let titles):
            if let temp = max.firstIndex(of: self.intValue) {
                self.cabValue = temp
            } else {
                self.cabValue = 0
            }
        default:
            do {}
        }
    }
}
