//
//  ProfileLineParserTests.swift
//
//
//  Created by Bartosz Polaczyk on 3/30/24.
//

import XCTest
@testable import ProfileReader

final class ProfileLineParserTests: XCTestCase {


    func testE2E() async throws {
        let parser = ProfileLineParser()
        let filesDir = try XCTUnwrap(Bundle.module.url(
            forResource: "TestData",
            withExtension: ""
        ))
        let fileURL = filesDir.appendingPathComponent("extended").appendingPathExtension("json")
        let fileProvider = JsonFileContentProvider(file: fileURL)
        let reader = FullProfileFileReader(fileProvider: fileProvider)
        for await line in reader.read() {
            parser.observed(newLine: line)
        }
        // TODO: implement real tests
        XCTAssertNotNil(parser.profileContext)
        XCTAssertFalse(parser.actions.isEmpty)
    }

}
