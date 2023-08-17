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
    
    case unexpectedBytes
    
    case userInfoNotFound
    case valueNotFound

    case parameterNotFound
    
    case indexOverFlow
}

func binaryString(doubleWords: Int32) -> [String] {
    let uint8array = (0..<4).map({ (doubleWords & (0xff << ($0 * 4))) >> ($0 * 4) })
    return uint8array.map({binaryString(byte: UInt8($0))}).flatMap({$0})
}

func binaryString(byte: UInt8) -> [String] {
    return (0..<8).map({ String((byte & (1 << (7 - $0))) >> (7 - $0)) })
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
            let cab_value = map_entry.cab.reduce(into: 0) { re, obj in
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
            
            return Effector(type: type, status: status_value, cab: cab_value, parameters: parameters)
        })
        
        return (name, effects)
    }
    
    static func parseDidChangeValue(bytes: [UInt8]) throws -> (Int, Int, Int){
        guard bytes.count == 10 else { throw PatchError.byteSizeNotCorrect }
        
        guard bytes[1] == 0x52 else { throw PatchError.unexpectedBytes }
        guard bytes[3] == 0x5f else { throw PatchError.unexpectedBytes }
        guard bytes[4] == 0x31 else { throw PatchError.unexpectedBytes }
        
        let effectNum = Int(bytes[5])
        let paramNum = Int(bytes[6])
        let value = (Int(bytes[7]) & 0b01111111) + ((Int(bytes[8]) & 0b00001111) << 7)

        print("value = \(value)")
            
        return (effectNum, paramNum, value)
    }
    
    init() {
        name = ""
        effects = []
        
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdatePatch(notification:)), name: .updatePatches, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateParameter(notification:)), name: .updateParameter, object: nil)
    }
    
    @objc func didUpdateParameter(notification: Notification) {
        do {
            guard let userInfo = notification.userInfo as? [String: Any] else { throw PatchError.userInfoNotFound }
            guard let parameter = userInfo["parameter"] as? Int else { throw PatchError.valueNotFound }
            guard let uuid = userInfo["UUID"] as? UUID else { throw PatchError.valueNotFound }
            
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
            
            guard let effectorIndex = effectorIndex else { throw PatchError.parameterNotFound }
            guard let parameterIndex = parameterIndex else { throw PatchError.parameterNotFound }
            
            if !self.effects[effectorIndex].params[parameterIndex].lock {
                
                let lsb = UInt8(parameter & 0b01111111)
                let msb = UInt8((parameter & 0b11110000000) >> 7)
                let bytes = [UInt8(0x52), UInt8(0x00), UInt8(0x5F), UInt8(0x31), UInt8(effectorIndex), UInt8(parameterIndex + 2), lsb, msb]
                let send_userInfo: [String: Any] = ["bytes": bytes]
                NotificationCenter.default.post(name: .requestBytes, object: nil, userInfo: send_userInfo)
            }
            self.effects[effectorIndex].params[parameterIndex].lock = false
        } catch {
            print(error)
        }
    }
    
    @objc func didUpdatePatch(notification: Notification) {
        do {
            guard let userInfo = notification.userInfo else { throw PatchError.userInfoNotFound }
            guard let bytes = userInfo["bytes"] as? [UInt8] else { throw PatchError.parameterNotFound }
            (self.name, self.effects) = try Patch.parseBytesForPatch(bytes: bytes)
            return
        } catch {
        }
        do {
            guard let userInfo = notification.userInfo else { throw PatchError.userInfoNotFound }
            guard let bytes = userInfo["bytes"] as? [UInt8] else { throw PatchError.parameterNotFound }
            let (effectNum, paramNum, value) = try Patch.parseDidChangeValue(bytes: bytes)
            print("didUpdatePatch")
            print(value)
            self.effects[effectNum].params[paramNum - 2].value = Float(value)
            self.effects[effectNum].params[paramNum - 2].floatValue = Float(value)
            self.effects[effectNum].params[paramNum - 2].intValue = value
        } catch {
        }
    }
        
    init(bytes: [UInt8]) throws {
        (self.name, self.effects) = try Patch.parseBytesForPatch(bytes: bytes)
    }
    
    func replace(effectorType: EffectorType, at index: Int) throws {
        guard index < 4 else { throw PatchError.indexOverFlow}
        
        let newEffector = Effector(type: effectorType)
        
        if index >= self.effects.count {
            self.effects.append(newEffector)
        } else {
            self.effects[index] = newEffector
        }
    }
    
    func binarize() throws -> [UInt8] {
        var bytes: [UInt8] = [
            0xf0,0x52,0x00,0x5f,0x28,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
            0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
            0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
            0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
            0x00,0x00,0x00,0x00,0x00,0x10,0x00,0x00,0x40,0x04,0x0f,0x45,0x6d,0x00,0x70,0x74,0x79,0x20,0x20,0x20,
            0x20,0x00,0x20,0x00,0xf7];
        
        bytes[0] = 0xF0
        bytes[1] = 0x52
        bytes[2] = 0x00
        bytes[3] = 0x5F
        bytes[4] = 0x28
        bytes[bytes.count-1] = 0xF7
        
        (0..<self.effects.count).forEach({
            let effect = self.effects[$0]
            let mapEntry = PatchBinaryMap.entry[$0]
            
            mapEntry.id.forEach { obj in
                bytes[obj.byteOffset] = bytes[obj.byteOffset] + UInt8((effect.type.number >> obj.bitOffset) & Int(obj.mask))
            }
            mapEntry.status.forEach { obj in
                bytes[obj.byteOffset] = bytes[obj.byteOffset] + UInt8((effect.status >> obj.bitOffset) & Int(obj.mask))
            }
            mapEntry.cab.forEach { obj in
                bytes[obj.byteOffset] = bytes[obj.byteOffset] + UInt8((effect.cab >> obj.bitOffset) & Int(obj.mask))
            }
            
            zip(mapEntry.params[0..<effect.type.parameters.count], effect.params[0..<effect.type.parameters.count]).forEach { (maps, param) in
                maps.forEach { map in
                    bytes[map.byteOffset] = bytes[map.byteOffset] + UInt8((param.intValue >> map.bitOffset) & Int(map.mask))
                }
            }
        })
                
        return bytes
    }
}
