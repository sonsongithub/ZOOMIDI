//
//  PatchBinaryMap.swift
//  ZOOMIDI
//
//  Created by Yuichi Yoshida on 2023/07/21.
//

import Foundation

struct DataByteMap {
    let byteOffset: Int
    let mask: Int
    let bitOffset: Int
    
    init?(dict: [String: Int]) {
        if let a = dict["byte_offset"], let b = dict["bit_offset"], let c = dict["mask"] {
            self.byteOffset = a
            self.bitOffset = b
            self.mask = c
        } else {
            return nil
        }
    }
}

struct EffectByteMap {
    let id: [DataByteMap]
    let status: [DataByteMap]
    let cab: [DataByteMap]
    let params: [[DataByteMap]]
}

enum PatchBinaryMapError: Error {
    case loadJsonFailed
    case idNotFound
    case statusNotFound
    case paramsNotFound
}

struct PatchBinaryMap {
    static var entry: [EffectByteMap] = []
    
    static func load() throws {
        guard let data = FileManager.default.contents(atPath: Bundle.main.path(forResource: "assign.json", ofType: nil)!) else { throw PatchBinaryMapError.loadJsonFailed }
        // convert to json object from Data
        let json = try JSONSerialization.jsonObject(with: data, options: [])

        // Cast json to Dictionary
        guard let data = json as? [[String: Any]] else { throw PatchBinaryMapError.loadJsonFailed }
        
        self.entry = try data.map { dict in
            guard let id = dict["id"] as? [[String: Int]] else { throw PatchBinaryMapError.idNotFound }
            let id_array = id.compactMap({DataByteMap(dict: $0)})
            
            guard let status = dict["status"] as? [[String: Int]] else { throw PatchBinaryMapError.statusNotFound }
            let status_array = status.compactMap({DataByteMap(dict: $0)})
            
            guard let status = dict["cab"] as? [[String: Int]] else { throw PatchBinaryMapError.statusNotFound }
            let cab_array = status.compactMap({DataByteMap(dict: $0)})
        
            guard let tmp_params = dict["params"] as? [Any] else { throw PatchBinaryMapError.paramsNotFound }
            let tmp_buf = tmp_params.compactMap({$0 as? [[String: Int]]})
            let params_array = tmp_buf.map { array in
                array.compactMap({DataByteMap(dict: $0)})
            }
            return EffectByteMap(id: id_array, status: status_array, cab: cab_array, params: params_array)
        }
    }
    
}
