//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 3/30/24.
//

import Foundation

public enum ProfileExplorerMode {
    // Reading a single profile that is already fully generated
    case fullFile(path: String)
}

// The main class responsible to read the profile and parse it to the internal model
public class ProfileExplorer {
    public typealias Parser = ProfileLineConsumer & ProfileStateProvider
    private let fileURL: URL
    private let profileReader: ProfileFileReader
    private let parser: Parser

    public init(path: String, mode: ProfileExplorerMode, parser: Parser) {
        let fileURL = URL(fileURLWithPath: path)
        self.fileURL = fileURL
        let fileProvider: FileContentProvider
        switch fileURL.pathExtension {
        case "gz":
            fileProvider = GzipFileContentProvider(file: fileURL)
        case "json":
            fileProvider = JsonFileContentProvider(file: fileURL)
        default:
            // unknown format - defaulting to json
            fileProvider = JsonFileContentProvider(file: fileURL)
        }
        self.profileReader = FullProfileFileReader(fileProvider: fileProvider)
        self.parser = parser
    }

    // It reading a single profile
    public func start() -> AsyncStream<ProfileContext> {
        return AsyncStream { continuation in
            Task {
                for await line in profileReader.read() {
                    let newContext = parser.observed(newLine: line)
                    continuation.yield(newContext)
                }
                continuation.finish()
            }
        }
    }
}
