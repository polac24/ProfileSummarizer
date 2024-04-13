//
//  ProfileLineParserTests.swift
//
//
//  Created by Bartosz Polaczyk on 3/30/24.
//

import XCTest
@testable import ProfileReader

final class ProfileLineParserIntgrationTests: XCTestCase {
    func testIntegration() async throws {
        let parser = ProfileLineParser()
        let filesDir = try XCTUnwrap(Bundle.module.url(
            forResource: "TestData",
            withExtension: ""
        ))
        let fileURL = filesDir.appendingPathComponent("sample").appendingPathExtension("json")
        let fileProvider = JsonFileContentProvider(file: fileURL)
        let reader = FullProfileFileReader(fileProvider: fileProvider)
        for await line in reader.read() {
            parser.observed(newLine: line)
        }
        XCTAssertEqual(parser.profileContext,BazelContext(uuid: UUID(uuidString: "d09047ad-ab82-42db-98bb-2352751ad2b4")!, date: Date(timeIntervalSince1970: 1712998740.463)))
        XCTAssertEqual(parser.actions.count, 7)
    }

}
