//
//  Patch.swift
//  ZOOMIDI
//
//  Created by Yuichi Yoshida on 2023/07/21.
//

import Foundation

enum PatchError: Error {
    case byteSizeNotCorrect
    case nameNotFound
}

class Patch: ObservableObject {
    @Published var name: String
    @Published var effects: [Effector] = []
    
    init(bytes: [UInt8]) throws {
        guard bytes.count == 105 else { throw PatchError.byteSizeNotCorrect }
        
        let indexForPatchName = [91, 92, 94, 95, 96, 97, 98, 99, 100, 102]
        
        let nameBytes = indexForPatchName.map { bytes[$0] }
        
        guard let name = String(bytes: nameBytes, encoding: .utf8) else { throw PatchError.nameNotFound }
        
        self.name = name
        
        //        let c0 = Int(bytes[88] & 0b01000000 >> 6)
        //        let c1 = Int(bytes[85] & 0b00001000 >> 3)
        //        let n0 = Int(bytes[89] & 0b00000100 >> 2)
        //        let df0 = Int(bytes[88] & 0b00000001 >> 9)

        self.effects = try PatchBinaryMap.entry[0..<4].map( { map_entry in
            let id_value = map_entry.id.reduce(into: 0) { re, obj in
                re = re + (Int(bytes[obj.byteOffset]) & obj.mask) << obj.bitOffset
            }
            let status_value = map_entry.status.reduce(into: 0) { re, obj in
                re = re + (Int(bytes[obj.byteOffset]) & obj.mask) << obj.bitOffset
            }
            let params: [Int] = map_entry.params.map({ param_map in
                let value = param_map.reduce(into: 0) { re, obj in
                    re = re + (Int(bytes[obj.byteOffset]) & obj.mask) << obj.bitOffset
                }
                return value
            })
            
            guard let type: EffectorType = EffectorType.data[id_value] else { throw NSError() }
           
            let parameters: [Parameter] = zip(type.parameters, params).map({ (parameterType, value) in
                return Parameter(value: value, type: parameterType)
            })
            
            return Effector(type: type, status: status_value, parameters: parameters)
        })
    }
}
