//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 3/30/24.
//

import Foundation

enum ProfileExplorerMode {
    // Reading a single profile that is already fully generated
    case fullFile(path: String)
}

// The main class responsible to read the profile and parse it to the internal model
class ProfileExplorer {
    private let fileURL: URL
    private let profileReader: ProfileFileReader
    private let parser: ProfileLineConsumer

    init(path: String, mode: ProfileExplorerMode, parser: ProfileLineConsumer) {
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
    func start() {
        let startedTask = Task {
            for await line in profileReader.read() {
                parser.observed(newLine: line)
            }
        }
    }
}
