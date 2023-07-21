//
//  ZOOMIDITests.swift
//  ZOOMIDITests
//
//  Created by Yuichi Yoshida on 2023/07/18.
//

import XCTest

enum TestError: Error {
    case resourceNotFound
}

final class ZOOMIDITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        EffectData.load()
        let manager = MIDIManager()
        guard let path = Bundle(for: self.classForCoder).path(forResource: "patchData01.bin", ofType: nil) else { throw TestError.resourceNotFound }
        let url = URL(filePath: path)
        let data = try Data(contentsOf: url)
        let bytes = data.withUnsafeBytes { pointer in
            let p = pointer.bindMemory(to: UInt8.self)
            return [UInt8](UnsafeBufferPointer(start: p.baseAddress, count: data.count))
        }
        do {
            try manager.parsePatchBytes(bytes: bytes)
        } catch {
            print(error)
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
