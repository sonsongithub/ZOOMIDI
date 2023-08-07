//
//  CustomUMPPacket.swift
//  ZOOMIDI
//
//  Created by Yuichi Yoshida on 2023/08/01.
//

import Foundation
import CoreMIDI

enum CustomUMPPacketError : Error {
    case undefinedStatus
    case notEvenNumberedLength
}

struct CustomUMPPacket {
    
    let mt: UInt32
    let group: UInt32
    let status: MIDI2SystemExclusiveStatus
    let length: UInt32
    let bytes: [UInt8]
    
    init(firstPacket: UInt32, secondPacket: UInt32) throws {
        mt = firstPacket >> 28
        group = (firstPacket >> 24) & UInt32(0x0f)
        let tmp_status = (firstPacket >> 20) & UInt32(0x0f)
        length = (firstPacket >> 16) & UInt32(0x0f)
        
        switch tmp_status {
        case 0:
            status = .one
        case 1:
            status = .start
        case 2:
            status = .continue
        case 3:
            status = .end
        default:
            throw CustomUMPPacketError.undefinedStatus
        }
        
        let a = [UInt8((firstPacket & 0xff000000) >> 24), UInt8((firstPacket & 0x00ff0000) >> 16), UInt8((firstPacket & 0x0000ff00) >> 8), UInt8((firstPacket & 0x000000ff) >> 0)]
        let b = [UInt8((secondPacket & 0xff000000) >> 24), UInt8((secondPacket & 0x00ff0000) >> 16), UInt8((secondPacket & 0x0000ff00) >> 8), UInt8((secondPacket & 0x000000ff) >> 0)]
        
        var uint8packets: [UInt8] = a + b
        if uint8packets.count > 0 {
            uint8packets.remove(at: 0)
        }
        if uint8packets.count > 0 {
            uint8packets.remove(at: 0)
        }
        bytes = Array(uint8packets[0..<Int(length)])
    }
    
    static func createCustomUMPPacketFromEventList(list: MIDIEventList.UnsafeSequence.Element) throws -> [CustomUMPPacket] {
        guard list.pointee.wordCount % 2 == 0 else { throw CustomUMPPacketError.notEvenNumberedLength }
        let words: [UInt32] = list.words().map({$0})
        let umps = words.chunked(into: 2)
        return try umps.map({ try CustomUMPPacket(firstPacket: $0[0], secondPacket: $0[1])})
    }
}
