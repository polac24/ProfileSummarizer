//
//  FileObserver.swift
//  
//
//  Created by Bartosz Polaczyk on 4/6/24.
//

import XCTest
@testable import ProfileReader

class FileObserverTests: XCTestCase {
    private(set) var workingDirectory: URL?
    let fileManager = FileManager.default

    @discardableResult
    func prepareTempDir(_ dirKey: String = #file) throws -> URL {
        if let dir = workingDirectory {
            return dir
        }
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(dirKey).resolvingSymlinksInPath()
        // Make sure the potentially dirty dir is removed
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        workingDirectory = url
        return url
    }

    override func setUp() async throws {
        try prepareTempDir()
    }

    func testDoesntKeepStrongReferenceAfterStarting() throws {
        let url = try XCTUnwrap(workingDirectory?.appendingPathComponent(#function))
        try "".write(to: url, atomically: true, encoding: .utf8)
        var observer: Optional = try FileObserver(url: url)
        try observer?.start {_ in }
        weak var weakObserver = observer
        XCTAssertNotNil(weakObserver)
        observer = nil
        XCTAssertNil(weakObserver)
    }

    func testDoesntKeepStrongReferenceAfterRestartingAndStopping() throws {
        let url = try XCTUnwrap(workingDirectory?.appendingPathComponent(#function))
        try "".write(to: url, atomically: true, encoding: .utf8)
        var observer: Optional = try FileObserver(url: url)
        try observer?.start {_ in }
        try DispatchQueue.global(qos: .userInteractive).sync {
            try "Overwritten".write(to: url, atomically: true, encoding: .utf8)
        }
        weak var weakObserver = observer
        XCTAssertNotNil(weakObserver)
        observer = nil
        XCTAssertNil(weakObserver)
    }

    func testDoesntKeepStrongReferenceBeforeStarting() throws {
        let url = try XCTUnwrap(workingDirectory?.appendingPathComponent(#function))
        try "".write(to: url, atomically: true, encoding: .utf8)
        var observer: Optional = try FileObserver(url: url)
        weak var weakObserver = observer
        XCTAssertNotNil(weakObserver)
        observer = nil
        XCTAssertNil(weakObserver)
    }

    func testCallsOnDelayedAppended() throws {
        let url = try XCTUnwrap(workingDirectory?.appendingPathComponent(#function))
        try "Initial".write(to: url, atomically: true, encoding: .utf8)
        let readExpectation = expectation(description: "Wrote data")
        var readStrings: String = ""
        let expectedFinalString = "Initialfirst data\ndelayed data\n"
        let observer = try FileObserver(url: url)
        try observer.start { dataString in
            readStrings.append(dataString)
            if readStrings == expectedFinalString && !dataString.isEmpty{
                readExpectation.fulfill()
            }
        }
        let fileHandler = try? FileHandle(forUpdating: url)
        Task {
            try fileHandler?.seekToEnd()
            try fileHandler?.write(contentsOf: "first data\n".data(using: .utf8)!)
            // sleep for 0.002 s to not batch both writes
            try await Task.sleep(nanoseconds: 2_000_000)
            try fileHandler?.write(contentsOf: "delayed data\n".data(using: .utf8)!)
        }
        waitForExpectations(timeout: 0.1)
    }

    func testCallsOnInitialData() throws {
        let url = try XCTUnwrap(workingDirectory?.appendingPathComponent(#function))
        try "Initial".write(to: url, atomically: true, encoding: .utf8)
        let readExpectation = expectation(description: "Wrote data")
        var readStrings: String = ""
        let expectedFinalString = "Initial"
        let observer = try FileObserver(url: url)
        try observer.start { dataString in
            readStrings.append(dataString)
            if readStrings == expectedFinalString && !dataString.isEmpty{
                readExpectation.fulfill()
            }
        }
        waitForExpectations(timeout: 0.1)
    }

    func testDoesntCallOnEmptyInitialData() throws {
        let url = try XCTUnwrap(workingDirectory?.appendingPathComponent(#function))
        try "".write(to: url, atomically: true, encoding: .utf8)
        let readExpectation = expectation(description: "Read data")
        readExpectation.isInverted = true

        let observer = try FileObserver(url: url)
        try observer.start { dataString in
            readExpectation.fulfill()
        }
        waitForExpectations(timeout: 0.1)
    }


    func testCallsOnWrite() throws {
        let url = try XCTUnwrap(workingDirectory?.appendingPathComponent(#function))
        try "Initial".write(to: url, atomically: true, encoding: .utf8)
        let readExpectation = expectation(description: "Wrote data")
        var readStrings: String = ""
        let expectedFinalString = "InitialOverwritten"
        let observer = try FileObserver(url: url)
        try observer.start { dataString in
            readStrings.append(dataString)
            if readStrings == expectedFinalString && !dataString.isEmpty{
                readExpectation.fulfill()
            }
        }
        Task {
            try "Overwritten".write(to: url, atomically: true, encoding: .utf8)
        }
        waitForExpectations(timeout: 0.1)
    }
}
