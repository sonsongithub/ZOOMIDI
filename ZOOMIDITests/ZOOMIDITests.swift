//
//  ZOOMIDITests.swift
//  ZOOMIDITests
//
//  Created by Yuichi Yoshida on 2023/07/18.
//

import XCTest

enum ZOOMIDITestError: Error {
    case resourceNotFound
}

final class ZOOMIDITests: XCTestCase {

    override func setUpWithError() throws {
        try EffectorType.load()
        try PatchBinaryMap.load()
    }

    override func tearDownWithError() throws {
    }
    
    func testLoadPachBinary() throws {
        guard let path = Bundle(for: self.classForCoder).path(forResource: "patchData01.bin", ofType: nil) else { throw ZOOMIDITestError.resourceNotFound }

        let url = URL(filePath: path)
        let data = try Data(contentsOf: url)
        let bytes = data.withUnsafeBytes { pointer in
            let p = pointer.bindMemory(to: UInt8.self)
            return [UInt8](UnsafeBufferPointer(start: p.baseAddress, count: data.count))
        }
        let _ = try Patch(bytes: bytes)
    }
    
    func testLoadAndWriteEffectorID() throws {
        
        EffectorType.data.keys.forEach {
            var bytes: [UInt8] = Array(repeating : UInt8(0), count : 105)
            
            let value: Int32 = Int32($0)
            
            PatchBinaryMap.entry[0].id.forEach { obj in
                bytes[obj.byteOffset] = bytes[obj.byteOffset] + UInt8((value >> obj.bitOffset) & Int32(obj.mask))
            }
            
            let id_value = PatchBinaryMap.entry[0].id.reduce(into: 0) { re, obj in
                re = re + (Int(bytes[obj.byteOffset]) & obj.mask) << obj.bitOffset
            }
            
            assert(value == id_value)
        }
    }
    
    func testPatchBinarize() throws {
//        var patch = Patch()
//
//        let keys = Array(EffectorType.data.keys)
//
//        try patch.replace(effectorType: EffectorType.data[keys[0]]!, at: 0)
//
//        let bytes = try patch.binarize()
//
//        let data = Data(bytes)
//        let dirPath = NSTemporaryDirectory()
//        let filePath = "\(dirPath)/hoge.bin"
//
//        print(dirPath)
//        try data.write(to: URL(fileURLWithPath: filePath))
//        print(filePath)
        
        guard let path = Bundle(for: self.classForCoder).path(forResource: "patchData01.bin", ofType: nil) else { throw ZOOMIDITestError.resourceNotFound }

        let url = URL(filePath: path)
        let data = try Data(contentsOf: url)
        let bytes = data.withUnsafeBytes { pointer in
            let p = pointer.bindMemory(to: UInt8.self)
            return [UInt8](UnsafeBufferPointer(start: p.baseAddress, count: data.count))
        }
        let patch = try Patch(bytes: bytes)
        
        let rewrite_bytes = try patch.binarize()

        let data_to_write = Data(rewrite_bytes)
        let dirPath = NSTemporaryDirectory()
        let filePath = "\(dirPath)/hoge.bin"

        print(dirPath)
        try data_to_write.write(to: URL(fileURLWithPath: filePath))
        print(filePath)
        
        for i in 0..<bytes.count {
            if bytes[i] != rewrite_bytes[i] {
                print("error----------------------------------------")
                print("index = \(i)")
                print("input = \(bytes[i]) - " + String(format: "%02X", bytes[i]))
                print("output = \(rewrite_bytes[i]) - " + String(format: "%02X", rewrite_bytes[i]))
            }
        }
        
//        zip(bytes, rewrite_bytes).enumerated().forEach { (index, input, output) in
//            if input != output {
//                print("error")
//                print("index = \(index)")
//                print("input = \(input)")
//                print("output = \(output)")
//            }
//        }
    }
}
