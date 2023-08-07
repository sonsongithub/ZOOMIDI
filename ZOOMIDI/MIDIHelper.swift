//
//  MIDIHelper.swift
//  ZOOMIDI
//
//  Created by Yuichi Yoshida on 2023/08/01.
//

import Foundation
import CoreMIDI

enum CoreMIDIError : Error {
    case canNotGetName
    case notFoundZOOMSeries
    case canNotGetUniqueID
    case canNotGetEndPoint
    case canNotCreateMIDIClient
    case canNotCreateInputPort
    case canNotCreateOutputPort
    case vacantBytes
}

/// Get source and destination devices that have the specified name.
/// If there are no source and destination devices that have the specified name and some errors are happened, this function throws error.
///
/// - Parameter deviceName: MIDI device name.
/// - Returns: Unique ID of source and destination devices.
/// - Throws: CoreMIDIError.
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
                throw CoreMIDIError.canNotGetName
            }
            if let temp = name?.takeRetainedValue() as? String {
                if temp == deviceName {
                    var tempInt32 = Int32(0)
                    result = MIDIObjectGetIntegerProperty(endPoint, kMIDIPropertyUniqueID, &tempInt32)
                    if result != noErr {
                        throw CoreMIDIError.canNotGetUniqueID
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
                throw CoreMIDIError.canNotGetName
            }
            if let temp = name?.takeRetainedValue() as? String {
                if temp == deviceName {
                    var tempInt32 = Int32(0)
                    result = MIDIObjectGetIntegerProperty(dest, kMIDIPropertyUniqueID, &tempInt32)
                    if result != noErr {
                        throw CoreMIDIError.canNotGetUniqueID
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
    throw CoreMIDIError.notFoundZOOMSeries
}

/// Get MIDIEndPointRef and MIDIObjectType from unique ID.
///
/// - Parameter uniqueID:
/// - Returns: MIDI end point and type of the MIDI end point.
/// - Throws: CoreMIDIError.
func getEndPoint(with uniqueID: Int32) throws -> (MIDIEndpointRef, MIDIObjectType) {
    var endPoint = MIDIEndpointRef()
    var foundObjectType = MIDIObjectType.device
    let result = MIDIObjectFindByUniqueID(uniqueID, &endPoint, &foundObjectType)
    if result != noErr {
        throw CoreMIDIError.canNotGetEndPoint
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
/// - Throws: CoreMIDIError.
func initInput(clientName:String, portName: String, block: @escaping MIDIReceiveBlock) throws -> (MIDIClientRef, MIDIPortRef) {
    var client = MIDIClientRef()
    var port = MIDIPortRef()
    var result = OSStatus()
    
    result = MIDIClientCreate(clientName as CFString, nil, nil, &client)
    if result != noErr {
        throw CoreMIDIError.canNotCreateMIDIClient
    }
    
    result = MIDIInputPortCreateWithProtocol(client, portName as CFString, ._1_0, &port, block)
    if result != noErr {
        throw CoreMIDIError.canNotCreateInputPort
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
    
    guard bytes.count > 0 else { throw CoreMIDIError.vacantBytes }
    
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

        let length: UInt32 = buf.count > 6 ? 6 : UInt32(buf.count)

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

extension Array {
    // split array into chunks of n
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
