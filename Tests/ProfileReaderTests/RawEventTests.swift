//
//  RawEventTests.swift
//  
//
//  Created by Bartosz Polaczyk on 3/30/24.
//

import XCTest
@testable import ProfileReader

final class RawEventTests: XCTestCase {
    private var decoder: JSONDecoder!
    override func setUp() {
        self.decoder = JSONDecoder()
    }

    func testReadsThread() throws {
        let input: Data = "{\"name\":\"thread_name\",\"ph\":\"M\",\"pid\":1,\"tid\":0,\"args\":{\"name\":\"Critical Path\"}}"
        let event = try decoder.decode(RawEvent.self, from: input)
        XCTAssertEqual(event, RawEvent(
            pid: 1, tid: 0, ph: "M", cat: nil, name: "thread_name", cname: nil, dur: nil, ts: nil, args: ["name": "Critical Path"]))
    }

    func testReadsGenralInformation() throws {
        let input: Data = "{\"cat\":\"general information\",\"name\":\"BazelDiffAwarenessModule.beforeCommand\",\"ph\":\"X\",\"ts\":15553,\"dur\":0,\"pid\":1,\"tid\":337}"
        let event = try decoder.decode(RawEvent.self, from: input)
        XCTAssertEqual(event, RawEvent(
            pid: 1, tid: 337, ph: "X", cat: "general information", name: "BazelDiffAwarenessModule.beforeCommand", cname: nil, dur: 0, ts: 15553, args: nil))
    }


    func testMemoryUsage() throws {
        let input: Data = "{\"name\":\"Memory usage (total)\",\"cname\":\"bad\",\"ph\":\"C\",\"ts\":137013553,\"pid\":1,\"tid\":337,\"args\":{\"system memory\":\"65314.369\"}}"
        let event = try decoder.decode(RawEvent.self, from: input)
        XCTAssertEqual(event, RawEvent(
            pid: 1, tid: 337, ph: "C", cat: nil, name: "Memory usage (total)", cname: "bad", dur: nil, ts: 137013553, args: ["system memory": "65314.369"]))
    }
}

extension Data: ExpressibleByStringLiteral{
    public init(stringLiteral:String) {
        self.init()
        // safe: UTF8 will always represent
        append(contentsOf: stringLiteral.data(using: .utf8)!)
    }
}
