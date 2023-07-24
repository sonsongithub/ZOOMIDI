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
    case effectTypeNotFound
}

func binaryString(byte: UInt8) -> [String] {
    return (0..<8).map({
        String((byte & (1 << (7 - $0))) >> (7 - $0))
    })
}

extension Notification.Name {
    static let updateParameter = Notification.Name("updateParameter")
}

class Patch: ObservableObject {
    @Published var name: String
    @Published var effects: [Effector] = []
    
    static func parseBytesForPatch(bytes: [UInt8]) throws -> (String, [Effector]) {
        guard bytes.count == 105 else { throw PatchError.byteSizeNotCorrect }
        
        let indexForPatchName = [91, 92, 94, 95, 96, 97, 98, 99, 100, 102]
        
        let nameBytes = indexForPatchName.map { bytes[$0] }
        
        guard let name = String(bytes: nameBytes, encoding: .utf8) else { throw PatchError.nameNotFound }
        
        //        let c0 = Int(bytes[88] & 0b01000000 >> 6)
        //        let c1 = Int(bytes[85] & 0b00001000 >> 3)
        //        let n0 = Int(bytes[89] & 0b00000100 >> 2)
        //        let df0 = Int(bytes[88] & 0b00000001 >> 9)

        let effects = try PatchBinaryMap.entry[0..<4].map( { map_entry in
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
            
            guard let type: EffectorType = EffectorType.data[id_value] else { throw PatchError.effectTypeNotFound }
           
            let parameters: [Parameter] = zip(type.parameters, params).map({ (parameterType, value) in
                return Parameter(value: value, type: parameterType)
            })
            
            return Effector(type: type, status: status_value, parameters: parameters)
        })
        
        return (name, effects)
    }
    
    static func parseDidChangeValue(bytes: [UInt8]) throws -> (Int, Int, Int){
        guard bytes.count == 10 else { throw NSError() }
        
        guard bytes[1] == 0x52 else { throw NSError() }
        guard bytes[3] == 0x5f else { throw NSError() }
        guard bytes[4] == 0x31 else { throw NSError() }
        
        let effectNum = Int(bytes[5])
        let paramNum = Int(bytes[6])
        let value = (Int(bytes[7]) & 0b01111111) + ((Int(bytes[8]) & 0b00001111) << 7)

        return (effectNum, paramNum, value)
    }
    
    init() {
        name = ""
        effects = []
        
        NotificationCenter.default.addObserver(self, selector: #selector(doSomething(notification:)), name: .updatePatches, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateParameter(notification:)), name: .updateParameter, object: nil)
    }
    
    @objc func didUpdateParameter(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any] else { return }
        
        guard let parameter = userInfo["parameter"] as? Int else { return }
        guard let uuid = userInfo["UUID"] as? UUID else { return }
        
        var effectorIndex: Int? = nil
        var parameterIndex: Int? = nil
        
        for i in 0..<self.effects.count {
            for j in 0..<self.effects[i].params.count {
                let parameter = self.effects[i].params[j]
                if parameter.id == uuid {
                    effectorIndex = i
                    parameterIndex = j
                }
            }
        }
        
        guard let effectorIndex = effectorIndex else { return }
        guard let parameterIndex = parameterIndex else { return }
        
//        0x52,0x00,0x58,0x31,nn,pp,vvLSB,vvMSB
        
        let lsb = UInt8(parameter & 0b01111111)
        
        let msb = UInt8((parameter & 0b11110000000) >> 7)
        
        
        let bytes = [UInt8(0x52), UInt8(0x00), UInt8(0x5F), UInt8(0x31), UInt8(effectorIndex), UInt8(parameterIndex + 2), lsb, msb]
        
        print(bytes.map({ String(format: "%02x", $0)}).joined(separator: " "))
        
        let send_userInfo: [String: Any] = ["bytes": bytes]
        NotificationCenter.default.post(name: .requestBytes, object: nil, userInfo: send_userInfo)
    }
    
    @objc func doSomething(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        guard let bytes = userInfo["bytes"] as? [UInt8] else { return }
        do {
            (self.name, self.effects) = try Patch.parseBytesForPatch(bytes: bytes)
        } catch {
            print(error)
        }
        do {
            let (effectNum, paramNum, value) = try Patch.parseDidChangeValue(bytes: bytes)
            self.effects[effectNum].params[paramNum - 2].value = Float(value)
            self.effects[effectNum].params[paramNum - 2].floatValue = Float(value)
            self.effects[effectNum].params[paramNum - 2].intValue = value
        } catch {
//            print(error)
        }
    }
        
    init(bytes: [UInt8]) throws {
        (self.name, self.effects) = try Patch.parseBytesForPatch(bytes: bytes)
    }
}
