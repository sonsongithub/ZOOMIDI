//
//  MIDIManager.swift
//  ZOOMIDI
//
//  Created by Yuichi Yoshida on 2023/07/17.
//

import Foundation
import CoreMIDI

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

extension Notification.Name {
    static let updatePatches = Notification.Name("UpdatePatches")
    static let updateValue = Notification.Name("updateValue")
}

struct EffectByteMap {
    let id: [DataByteMap]
    let status: [DataByteMap]
    let params: [[DataByteMap]]
}

/// Get source and destination devices that have the specified name.
/// If there are no source and destination devices that have the specified name and some errors are happened, this function throws error.
///
/// - Parameter deviceName: MIDI device name.
/// - Returns: Unique ID of source and destination devices.
/// - Throws: NSError.
func getEndPointIDsThatHave(deviceName: String = "ZOOM MS Series") throws -> (Int32, Int32) {
    var destinationUniqueID: Int32?
    var sourceUniqueID: Int32?
    var result = noErr

    for i in 0..<MIDIGetNumberOfDevices() {
        do {
            let endPoint = MIDIGetDestination(i)
            var name: Unmanaged<CFString>?
            result = MIDIObjectGetStringProperty(endPoint, kMIDIPropertyDisplayName, &name)
            if result != noErr {
                throw NSError(domain: "com.sonson.CoreMIDI", code: 0)
            }
            if let temp = name?.takeRetainedValue() as? String {
                if temp == deviceName {
                    var tempInt32 = Int32(0)
                    result = MIDIObjectGetIntegerProperty(endPoint, kMIDIPropertyUniqueID, &tempInt32)
                    if result != noErr {
                        throw NSError(domain: "com.sonson.CoreMIDI", code: 1)
                    }
                    destinationUniqueID = tempInt32
                    break
                }
            }
        }
    }
    for i in 0..<MIDIGetNumberOfDevices() {
        do {
            let dest = MIDIGetSource(i)
            var name: Unmanaged<CFString>?
            result = MIDIObjectGetStringProperty(dest, kMIDIPropertyDisplayName, &name)
            if result != noErr {
                throw NSError(domain: "com.sonson.CoreMIDI", code: 0)
            }
            if let temp = name?.takeRetainedValue() as? String {
                if temp == deviceName {
                    var tempInt32 = Int32(0)
                    result = MIDIObjectGetIntegerProperty(dest, kMIDIPropertyUniqueID, &tempInt32)
                    if result != noErr {
                        throw NSError(domain: "com.sonson.CoreMIDI", code: 1)
                    }
                    sourceUniqueID = tempInt32
                    break
                }
            }
        }
    }
    if let t1 = destinationUniqueID, let t2 = sourceUniqueID {
        return (t1, t2)
    }
    throw NSError(domain: "com.sonson.CoreMIDI", code: 2)
}

/// Get MIDIEndPointRef and MIDIObjectType from unique ID.
///
/// - Parameter uniqueID:
/// - Returns: MIDI end point and type of the MIDI end point.
/// - Throws: NSError.
func getEndPoint(with uniqueID: Int32) throws -> (MIDIEndpointRef, MIDIObjectType) {
    var endPoint = MIDIEndpointRef()
    var foundObjectType = MIDIObjectType.device
    var result = MIDIObjectFindByUniqueID(uniqueID, &endPoint, &foundObjectType)
    if result != noErr {
        throw NSError()
    }
    return (endPoint, foundObjectType)
}

/// Get MIDIClientRef and MIDIPortRef that can receive MIDI message.
///
/// - Parameters:
///   - clientName: The name of MIDI client.
///   - portName: The name of MIDI port.
///   - block: A callback block the system invokes with incoming MIDI from sources connected to this port.
/// - Returns: MIDI client and MIDI port to receive MIDI message.
/// - Throws: NSError.
func initInput(clientName:String, portName: String, block: @escaping MIDIReceiveBlock) throws -> (MIDIClientRef, MIDIPortRef) {
    var client = MIDIClientRef()
    var port = MIDIPortRef()
    var result = OSStatus()
    
    result = MIDIClientCreate(clientName as CFString, nil, nil, &client)
    if result != noErr {
        throw NSError()
    }
    
    result = MIDIInputPortCreateWithProtocol(client, portName as CFString, ._1_0, &port, block)
    if result != noErr {
        throw NSError()
    }
    
    return (client, port)
}

func old_initInput(clientName:String, portName: String, block: @escaping MIDIReadBlock) throws -> (MIDIClientRef, MIDIPortRef) {
    var client = MIDIClientRef()
    var port = MIDIPortRef()
    var result = OSStatus()
    
    result = MIDIClientCreate(clientName as CFString, nil, nil, &client)
    if result != noErr {
        throw NSError()
    }
    
    result = MIDIInputPortCreateWithBlock(client, clientName as CFString, &port, block)
    
//    result = MIDIInputPortCreateWithProtocol(client, portName as CFString, ._2_0, &port, block)
    if result != noErr {
        throw NSError()
    }
    
    return (client, port)
}

enum MIDI2SystemExclusiveStatus {
    case one
    case start
    case `continue`
    case end
    
    var value: UInt32 {
        switch self {
        case .one:
            return 0
        case .start:
            return 1
        case .continue:
            return 2
        case .end:
            return 3
        }
    }
}

func eventListUMP8Byte2UInt8(list: UnsafePointer<MIDIEventList> ) -> [UInt8] {
    
    let num = list.pointee.numPackets
        
    let tmp:[[UInt8]] = list.unsafeSequence().map { element -> [UInt8] in
        let mt = element.pointee.words.0 >> 28
        let group = (element.pointee.words.0 >> 24) & UInt32(0x0f)
        let status = (element.pointee.words.0 >> 20) & UInt32(0x0f)
        let length = (element.pointee.words.0 >> 16) & UInt32(0x0f)
        print("mt=\(mt)")
        print("group=\(group)")
        print("status=\(status)")
        print("length=\(length)")
        
        var uint8packets: [UInt8] = element.words().map({
            
            return [UInt8(($0 & 0xff000000) >> 24), UInt8(($0 & 0x00ff0000) >> 16), UInt8(($0 & 0x0000ff00) >> 8), UInt8(($0 & 0x000000ff) >> 0)]
        }).flatMap({$0})
        
        if uint8packets.count > 0 {
            uint8packets.remove(at: 0)
        }
        if uint8packets.count > 0 {
            uint8packets.remove(at: 0)
        }
        return Array(uint8packets[0..<Int(length)])
    }
    
    return tmp.flatMap({$0})
}

/// This function converts MIDI1.0 System Exclusive message to MIDI2.0 8-Byte UMP Formats.
/// MIDI2.0 messages are returned as UInt32 arrays.
/// Please refer to Universal MIDI Packet (UMP) Format and MIDI 2.0 Protocol
///
/// - Parameters:
///   - bytes: MIDI1.0 System Exclusive message as UInt8 array.
/// - Returns: MIDI2.0 messages are returned as UInt32 arrays.
/// - Throws: NSError.
func convertSysExMIDI1toMIDI2UMP8(bytes: [UInt8]) throws -> [UInt32] {
    var buf = bytes
    
    guard bytes.count > 0 else { throw NSError() }
    
    if bytes.count > 3 {
        // Remove status bytes from system exclusive if they are included in bytes.
        if buf[0] == UInt8(0xF0) {
            buf.remove(at: 0)
        }
        if buf[buf.count-1] == UInt8(0xF7) {
            buf.removeLast()
        }
    }

    var result: [UInt32] = []
    
    while buf.count > 0 {
        var status: MIDI2SystemExclusiveStatus = .continue
        if result.count == 0 && buf.count <= 6 {
            status = .one
        }
        if result.count == 0 && buf.count > 6 {
            status = .start
        }
        if result.count > 0 && buf.count <= 6 {
            status = .end
        }

        var length: UInt32 = buf.count > 6 ? 6 : UInt32(buf.count)

        var word0: UInt32 = UInt32(0x30) << 24 + (status.value << 20) + (UInt32(length) << 16)
        if buf.count > 0 {
            word0 = word0 + UInt32(buf[0]) << 8
            buf.remove(at: 0)
        }
        if buf.count > 0 {
            word0 = word0 + UInt32(buf[0])
            buf.remove(at: 0)
        }
        var word1: UInt32 = 0
        var counter: Int = 3
        while buf.count > 0 && counter >= 0 {
            word1 = word1 + UInt32(buf[0]) << (8 * counter)
            buf.remove(at: 0)
            counter-=1
        }
        result.append(word0)
        result.append(word1)
    }
    return result
}

func parsePathDidChange(bytes: [UInt8]) {
    guard bytes.count == 10 else { return }
    
    guard bytes[1] == 0x52 else { return }
    guard bytes[3] == 0x5f else { return }
    guard bytes[4] == 0x31 else { return }
    
    let effectNum = Int(bytes[5])
    let paramNum = Int(bytes[6])
    let value = Int(bytes[7])
    
    let userInfo: [String: Int] = [
        "effectNum": effectNum,
        "paramNum": paramNum,
        "value": value,
    ]
    DispatchQueue.main.async {
        NotificationCenter.default.post(name: .updateValue, object: nil, userInfo: userInfo)
    }
}

class MIDIManager {
    
    var destination = MIDIDeviceRef()
    var destionationPort = MIDIPortRef()
    var map_array: [EffectByteMap] = []
    
    
    func parsePatchBytes(bytes: [UInt8]) throws -> [Effect] {
        guard bytes.count == 105 else { throw NSError() }
        
        let indexForPatchName = [91, 92, 94, 95, 96, 97, 98, 99, 100, 102]
        
        let nameBytes = indexForPatchName.map { bytes[$0] }
        
        if let name = String(bytes: nameBytes, encoding: .utf8) {
            print(name)
        }
        
//        let c0 = Int(bytes[88] & 0b01000000 >> 6)
//        let c1 = Int(bytes[85] & 0b00001000 >> 3)
//        let n0 = Int(bytes[89] & 0b00000100 >> 2)
//        let df0 = Int(bytes[88] & 0b00000001 >> 9)
        
        let objs = try map_array[0..<4].map( { map_entry in
            print("-----------------------")
            let id_value = map_entry.id.reduce(into: 0) { re, obj in
                re = re + (Int(bytes[obj.byteOffset]) & obj.mask) << obj.bitOffset
            }
            print(String(format: "%02x", id_value))
            
            let status_value = map_entry.status.reduce(into: 0) { re, obj in
                re = re + (Int(bytes[obj.byteOffset]) & obj.mask) << obj.bitOffset
            }
            print(String(format: "%02x", status_value))
            let params = map_entry.params.map({ param_map in
                let value = param_map.reduce(into: 0) { re, obj in
                    re = re + (Int(bytes[obj.byteOffset]) & obj.mask) << obj.bitOffset
                }
                return value
            })
            
            guard let template = EffectData.data[id_value] else { throw NSError() }
            
            return Effect(template: template, effectId: id_value, status: status_value, values: params, params: template.parameters)
        })
        return objs
    }
    
    init() {
        
        // ファイルの内容 Data オブジェクトとして読み込む
        
        if let data = FileManager.default.contents(atPath: Bundle.main.path(forResource: "assign.json", ofType: nil)!) {
            do {
                // Data オブジェクトを JSON オブジェクトに変換
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                // JSON オブジェクトを Dictionary にキャスト
                if let dictionary = json as? [Any] {
                    let data = dictionary.compactMap({ $0 as? [String: Any]})
                    let t = try data.map { dict in
                        guard let id = dict["id"] as? [[String: Int]] else { throw NSError() }
                        let id_array = id.compactMap({DataByteMap(dict: $0)})
                        
                        guard let status = dict["status"] as? [[String: Int]] else { throw NSError() }
                        let status_array = status.compactMap({DataByteMap(dict: $0)})
                    
                        guard let tmp_params = dict["params"] as? [Any] else { throw NSError() }
                        let tmp_buf = tmp_params.compactMap({$0 as? [[String: Int]]})
                        let params_array = tmp_buf.map { array in
                            array.compactMap({DataByteMap(dict: $0)})
                        }
                        return EffectByteMap(id: id_array, status: status_array, params: params_array)
                    }
                    print(t.count)
                    map_array.append(contentsOf: t)
                }
            } catch {
                print("JSON ファイルの読み取りエラー: \(error.localizedDescription)")
            }
        }
        do {
            let (destinationUniqueID, sourceUniqueID) = try getEndPointIDsThatHave()
            let (destination, _) = try getEndPoint(with: destinationUniqueID)
            let (source, _) = try getEndPoint(with: sourceUniqueID)
            
            var outputPort = MIDIPortRef()
            var destinationClient = MIDIClientRef()
            var result = MIDIClientCreate("test" as CFString, nil, nil, &destinationClient)
            result = MIDIOutputPortCreate(destinationClient, "output" as CFString, &outputPort)
            if result != noErr {
                throw NSError()
            }
            self.destination = destination
            self.destionationPort = outputPort
            
            //        let (_, sourcePort) = try initInput(clientName: "clientDest", portName: "portDest", block: self.receive(listPointer:context:))
            
            let (_, sourcePort) = try old_initInput(clientName: "clientDest", portName: "portDest", block: self.receive(listPointer:context:))
            MIDIPortConnectSource(sourcePort, source, nil)
        } catch {
            print(error)
        }
    }
    
    func send(messages: [UInt8]) throws {
        let ump = try convertSysExMIDI1toMIDI2UMP8(bytes: messages)
        self.send(messages: ump)
    }
    
    func send(messages: [UInt32]) {
        var eventList: MIDIEventList = .init()
        let packet = MIDIEventListInit(&eventList, ._2_0)
        MIDIEventListAdd(&eventList, 1024, packet, 0, messages.count, messages)
        MIDISendEventList(self.destionationPort, destination, &eventList)
    }
    
    enum Status {
        case wait
        case receiving
    }
    
    var status = Status.wait
    var buffer: [UInt8] = []
    
    func receive(listPointer: UnsafePointer<MIDIPacketList>, context: UnsafeMutableRawPointer?) -> Void {
        listPointer.unsafeSequence().forEach { pointer in
            let length = Int(pointer.pointee.length)
            var tmp = pointer.pointee.data
            var buf: [UInt8] = []
            withUnsafePointer(to: &tmp) { p in
                p.withMemoryRebound(to: UInt8.self, capacity: length) { pp in
                    for i in 0..<length {
                        buf.append((pp + i).pointee)
                    }
                }
            }
            
            if buf[0] == 0xf0 {
                self.buffer.removeAll()
            }
            self.buffer.append(contentsOf: buf)
            if buf.last == 0xf7 {
                let output = self.buffer.map({String(format: "%02x", $0)}).joined(separator: " ")
                print(output)
                DispatchQueue.main.async {
                    do {
                        let objs = try self.parsePatchBytes(bytes: self.buffer)
                        NotificationCenter.default.post(name: .updatePatches, object: nil, userInfo: ["values": objs])
                    } catch {
//                        print(error)
                    }
                }
//                parsePathDidChange(bytes: self.buffer)
            }
        }
    }

    func receive(listPointer: UnsafePointer<MIDIEventList>, context: UnsafeMutableRawPointer?) -> Void {
    }
    
    func start() {
        do {
            try self.send(messages: [UInt8(0x7e), UInt8(0x00), UInt8(0x06), UInt8(0x01)])
            try self.send(messages: [UInt8(0x52), UInt8(0x00), UInt8(0x5f), UInt8(0x50)])
            try self.send(messages: [UInt8(0x52), UInt8(0x00), UInt8(0x5f), UInt8(0x29)])
        } catch {
            print(error)
        }
    }
}
