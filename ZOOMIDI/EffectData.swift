//
//  EffectData.swift
//  ZOOMIDI
//
//  Created by Yuichi Yoshida on 2023/07/17.
//

import Foundation

protocol EffectParameter: Identifiable {
    var name: String { get }
    var `default`: Int { get }
    var id: UUID { get }
}

struct EffectSingleParam : EffectParameter {
    let name: String
    let `default`: Int
    let max: Int
    let offset: Int
    let id = UUID()
}

struct EffectListedParam : EffectParameter {
    let name: String
    let `default`: Int
    let max: Int
    let titles: [String]
    let id = UUID()
}

struct EffectTitlesAndValuesParam : EffectParameter {
    let name: String
    let `default`: Int
    let max: [Int]
    let list: [String]
    let id = UUID()
}

struct EffectCABParam: EffectParameter {
    let name: String
    let `default`: Int
    let max: Int
    let list: [String]
    let disp_type: String
    let disp_min: Int
    let disp_max: Int
    let id = UUID()
}

struct EffectData {
    let name: String
    let group: String
    let order: Int
    let install: Int
    let version: Int
    let title: String
    let dsp: Float
    let dspMax: Float
    let dspMin: Float
    let parameters: [any EffectParameter]
    let id = UUID()
    
    enum EffectDataError: Error {
        case TemplateParamNameNotFound
        case TemplateParamDefNotFound
        case TemplateParamMaxDispParseError
        case TemplateCABParseError
    }
    
    static var data: [Int: EffectData] = [:]
    static func load() {
        if let data = FileManager.default.contents(atPath: Bundle.main.path(forResource: "effect_v1.json", ofType: nil)!) {
            do {
                // Data オブジェクトを JSON オブジェクトに変換
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let rootJson = json as? [String: Any] {
                    try rootJson.keys.sorted().forEach { effect_number in
                        guard let info = rootJson[effect_number] as? [String : Any] else { throw NSError() }
                        guard let name = info["name"] as? String else { throw NSError() }
                        guard let dsp = info["dsp"] as? Double else { throw NSError() }
                        guard let dspmax = info["dspmax"] as? Double else { throw NSError() }
                        guard let dspmin = info["dspmin"] as? Double else { throw NSError() }
                        guard let group = info["group"] as? String else { throw NSError() }
                        guard let order = info["order"] as? Int else { throw NSError() }
                        guard let install = info["install"] as? Int else { throw NSError() }
                        guard let version = info["ver"] as? Int else { throw NSError() }
                        guard let param = info["param"] as? [[String:Any]] else { throw NSError() }
                        var title = "THROUGH"
                        if info["title"] != nil {
                            guard let tmp = info["title"] as? String else { throw NSError() }
                            title = tmp
                        }
                        let templates: [any EffectParameter] = try param.map({
                            guard let name = $0["name"] as? String else { throw EffectDataError.TemplateParamNameNotFound  }
                            guard let def = $0["def"] as? Int else { throw EffectDataError.TemplateParamDefNotFound }
                            switch ($0["max"], $0["disp"]) {
                            case let (max as Int, nil):
                                return EffectSingleParam(name: name, default: def, max: max, offset: 0)
                            case let (max as Int, disp as Int):
                                return EffectSingleParam(name: name, default: def, max: max, offset: disp)
                            case let (max as Int, disp as [String]):
                                return EffectListedParam(name: name, default: def, max: max, titles: disp)
                            case let (max as [Int], disp as [String]):
                                return EffectTitlesAndValuesParam(name: name, default: def, max: max, list: disp)
                            case let (max as Int, disp as [String: Any]):
                                guard let type = disp["type"] as? String else { throw EffectDataError.TemplateCABParseError}
                                guard let disp_min = disp["min"] as? Int else { throw EffectDataError.TemplateCABParseError}
                                guard let disp_max = disp["max"] as? Int else { throw EffectDataError.TemplateCABParseError}
                                guard let list = disp["list"] as? [String] else { throw EffectDataError.TemplateCABParseError}
                                return EffectCABParam(name: name, default: def, max: max, list: list, disp_type: type, disp_min: disp_min, disp_max: disp_max)
                            default:
                                print("------------------------------")
                                throw EffectDataError.TemplateParamMaxDispParseError
                            }
                        })
                        if let int_effect_number = Int(effect_number) {
                            EffectData.data[int_effect_number] = EffectData(name: name,
                                                                        group: group,
                                                                        order: order,
                                                                        install: install,
                                                                        version: version,
                                                                        title: title,
                                                                        dsp: Float(dsp),
                                                                        dspMax: Float(dspmax),
                                                                        dspMin: Float(dspmin),
                                                                        parameters: templates)
                        }
                    }
                }
            } catch {
                print("JSON ファイルの読み取りエラー: \(error.localizedDescription)")
            }
        }
    }
}
