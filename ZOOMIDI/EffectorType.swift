//
//  EffectorType.swift
//  ZOOMIDI
//
//  Created by Yuichi Yoshida on 2023/07/21.
//

import Foundation

struct EffectorType {
    let name: String
    let group: String
    let order: Int
    let install: Int
    let version: Int
    let title: String
    let dsp: Float
    let dspMax: Float
    let dspMin: Float
    let parameters: [ParameterType]
    let number: Int
    let id = UUID()
    
    internal enum EffectorTypeLoadError: Error {
        case numberNotFound
        case parseFailed
        case itemNotFound
        case anyParameterNotFound
        case parameterParseFailed
        case resourceLoadFailed
    }
    
    static var data: [Int: EffectorType] = [:]
    
    static func load() throws {
        
        func loadEffectorInfoFromJsonDict(dict: [String: Any]) throws -> (String, Double, Double, Double, String, Int, Int, Int, String, [[String: Any]]) {
            guard let name = dict["name"] as? String else { throw EffectorTypeLoadError.itemNotFound }
            guard let dsp = dict["dsp"] as? Double else { throw EffectorTypeLoadError.itemNotFound }
            guard let dspmax = dict["dspmax"] as? Double else { throw EffectorTypeLoadError.itemNotFound }
            guard let dspmin = dict["dspmin"] as? Double else { throw EffectorTypeLoadError.itemNotFound }
            guard let group = dict["group"] as? String else { throw EffectorTypeLoadError.itemNotFound }
            guard let order = dict["order"] as? Int else { throw EffectorTypeLoadError.itemNotFound }
            guard let install = dict["install"] as? Int else { throw EffectorTypeLoadError.itemNotFound }
            guard let version = dict["ver"] as? Int else { throw EffectorTypeLoadError.itemNotFound }
            guard let param = dict["param"] as? [[String:Any]] else { throw EffectorTypeLoadError.itemNotFound }
            var title = "THROUGH"
            if dict["title"] != nil {
                guard let tmp = dict["title"] as? String else { throw EffectorTypeLoadError.itemNotFound }
                title = tmp
            }
            return (name, dsp, dspmax, dspmin, group, order, install, version, title, param)
        }
        
        func loadParameterFromJsonDict(dict: [String: Any]) throws -> ParameterType {
            guard let name = dict["name"] as? String else { throw EffectorTypeLoadError.parameterParseFailed  }
            guard let def = dict["def"] as? Int else { throw EffectorTypeLoadError.parameterParseFailed }
            
            switch (dict["max"], dict["disp"]) {
            case let (max as Int, nil):
                return .single(name: name, default: def, max: max, offset: 0)
            case let (max as Int, disp as Int):
                return .single(name: name, default: def, max: max, offset: disp)
            case let (max as Int, disp as [String]):
                return .list(name: name, default: def, max: max, titles: disp)
            case let (max as [Int], disp as [String]):
                return .pair(name: name, default: def, max: max, titles: disp)
            case let (max as Int, disp as [String: Any]):
                guard let type = disp["type"] as? String else { throw EffectorTypeLoadError.parameterParseFailed }
                guard let disp_min = disp["min"] as? Int else { throw EffectorTypeLoadError.parameterParseFailed }
                guard let disp_max = disp["max"] as? Int else { throw EffectorTypeLoadError.parameterParseFailed }
                guard let list = disp["list"] as? [String] else { throw EffectorTypeLoadError.parameterParseFailed }
                return .cab(name: name, default: def, max: max, disp_type: type, disp_max: disp_max, disp_min: disp_min, titles: list)
            default:
                throw EffectorTypeLoadError.parameterParseFailed
            }
        }
        
        guard let path = Bundle.main.path(forResource: "effect_v1.json", ofType: nil) else { throw EffectorTypeLoadError.resourceLoadFailed }
        guard let data = FileManager.default.contents(atPath: path) else { throw EffectorTypeLoadError.resourceLoadFailed }

        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        guard let rootJson = json as? [String: Any] else { throw EffectorTypeLoadError.numberNotFound }
        
        let tmp: [(Int, EffectorType)] = try rootJson.map { (effectNumber: String, value: Any) in
            guard let dict = value as? [String : Any] else { throw EffectorTypeLoadError.parseFailed }
            let (name, dsp, dspmax, dspmin, group, order, install, version, title, param) = try loadEffectorInfoFromJsonDict(dict: dict)
            var loadedTypes: [ParameterType] = try param.map({ try loadParameterFromJsonDict(dict: $0)})
            
            for _ in 0..<(9 - loadedTypes.count) {
                loadedTypes.append(.none)
            }
            
            guard let effectNumberAsInt = Int(effectNumber) else { throw EffectorTypeLoadError.parseFailed }
            let type = EffectorType(name: name, group: group, order: order, install: install, version: version, title: title, dsp: Float(dsp), dspMax: Float(dspmax), dspMin: Float(dspmin), parameters: loadedTypes, number: effectNumberAsInt)
            return (effectNumberAsInt, type)
        }
        EffectorType.data = Dictionary(uniqueKeysWithValues: tmp)
    }
}
