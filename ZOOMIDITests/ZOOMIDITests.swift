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
        let patch = try Patch(bytes: bytes)
    }
}
