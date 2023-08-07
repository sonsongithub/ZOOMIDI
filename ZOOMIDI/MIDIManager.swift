//
//  MIDIManager.swift
//  ZOOMIDI
//
//  Created by Yuichi Yoshida on 2023/07/17.
//

import Foundation
import CoreMIDI

extension Notification.Name {
    static let updatePatches = Notification.Name("UpdatePatches")
    static let updateValue = Notification.Name("updateValue")
    static let requestBytes = Notification.Name("requestBytes")
}

class MIDIManager {
    var destination = MIDIDeviceRef()
    var destionationPort = MIDIPortRef()
    
    init() {
        
        do {
            let (destinationUniqueID, sourceUniqueID) = try getEndPointIDsThatHave()
            let (destination, _) = try getEndPoint(with: destinationUniqueID)
            let (source, _) = try getEndPoint(with: sourceUniqueID)
            var result = OSStatus()
            var outputPort = MIDIPortRef()
            var destinationClient = MIDIClientRef()
            result = MIDIClientCreate("test" as CFString, nil, nil, &destinationClient)
            if result != noErr {
                throw CoreMIDIError.canNotCreateOutputPort
            }
            result = MIDIOutputPortCreate(destinationClient, "output" as CFString, &outputPort)
            if result != noErr {
                throw CoreMIDIError.canNotCreateOutputPort
            }
            self.destination = destination
            self.destionationPort = outputPort
            
            let (_, sourcePort) = try initInput(clientName: "clientDest", portName: "portDest", block: self.receive(listPointer:context:))
            
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
    
    @objc func didReceiveRequest(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any] else { return }
        guard let bytes = userInfo["bytes"] as? [UInt8] else { return }
        do {
            try self.send(messages: bytes)
        } catch {
            print(error)
        }
    }
    
    var status = Status.wait
    var buffer: [UInt8] = []
    
    func receive(listPointer: UnsafePointer<MIDIEventList>, context: UnsafeMutableRawPointer?) -> Void {
        do {
            let customPackets = try listPointer
                .unsafeSequence()
                .map({ try CustomUMPPacket.createCustomUMPPacketFromEventList(list: $0)})
                .flatMap({ $0 })
            
            customPackets.forEach { packet in
                switch packet.status {
                case .one:
                    self.buffer = [UInt8(0xF0)]
                    self.buffer.append(contentsOf: packet.bytes)
                    self.buffer.append(UInt8(0xF7))
                    let temp = self.buffer
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .updatePatches, object: nil, userInfo: ["bytes": temp])
                    }
                case .start:
                    self.buffer = [UInt8(0xF0)]
                    self.buffer.append(contentsOf: packet.bytes)
                case .continue:
                    self.buffer.append(contentsOf: packet.bytes)
                case .end:
                    self.buffer.append(contentsOf: packet.bytes)
                    self.buffer.append(UInt8(0xF7))
                    let temp = self.buffer
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .updatePatches, object: nil, userInfo: ["bytes": temp])
                    }
                }
            }
            
        } catch {
            print(error)
        }
    }
    
    func start() {
        do {
            NotificationCenter.default.addObserver(self, selector: #selector(didReceiveRequest(notification:)), name: .requestBytes, object: nil)
            try self.send(messages: [UInt8(0x7e), UInt8(0x00), UInt8(0x06), UInt8(0x01)])
            try self.send(messages: [UInt8(0x52), UInt8(0x00), UInt8(0x5f), UInt8(0x50)])
            try self.send(messages: [UInt8(0x52), UInt8(0x00), UInt8(0x5f), UInt8(0x29)])
        } catch {
            print(error)
        }
    }
}
