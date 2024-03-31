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
        let fileURL = URL(fileURLWithPath: "/private/var/tmp/_bazel_bartosz/profiles/uploaded/index-build-profile-02F1803F-03CA-4ECE-9618-9D92A960EFC2.raw.json")
        let fileProvider = JsonFileContentProvider(file: fileURL)
        let reader = FullProfileFileReader(fileProvider: fileProvider)
        for await line in reader.read() {
            parser.observed(newLine: line)
        }
        print(parser.profileContext)
    }

}
