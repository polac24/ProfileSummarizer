//
//  BazelActionTests.swift
//  
//
//  Created by Bartosz Polaczyk on 4/6/24.
//

import XCTest
@testable import ProfileReader

final class BazelActionTests: XCTestCase {
    private func buildParserStateWith(actionName: String) -> ProfileLineParserState {
        let (newState, _) = ProfileLineParserState().transform(.init(pid: 0, tid: 0, ph: "", cat: nil, name: actionName, cname: nil, dur: 1, ts: 0, args: ["mnemonic":"demoMnemonic"]))
        return newState
    }

    func testExtractsBazelTargetForExternalRepos() {
        let state = buildParserStateWith(actionName: "Creating source manifest for @rule_name//generator/Module:Target")
        XCTAssertEqual(BazelAction.from(state)?.target, "@rule_name//generator/Module:Target")
    }

    func testExtractsBazelDefaultModuleTarget() {
        let state = buildParserStateWith(actionName: "Creating source manifest for @rule_name//generator/Module")
        XCTAssertEqual(BazelAction.from(state)?.target, "@rule_name//generator/Module")
    }

    func testExtractsBazelInternalTarget() {
        let state = buildParserStateWith(actionName: "Creating source manifest for //generator/Module")
        XCTAssertEqual(BazelAction.from(state)?.target, "//generator/Module")
    }

    func testExtractsFirstBazelTarget() {
        let state = buildParserStateWith(actionName: "Creating source manifest for //generator/Module and //other:Target")
        XCTAssertEqual(BazelAction.from(state)?.target, "//generator/Module")
    }

    func testReturnsNilForOtherNames() {
        let state = buildParserStateWith(actionName: "Preparing")
        XCTAssertNil(BazelAction.from(state)?.target)
    }
}
