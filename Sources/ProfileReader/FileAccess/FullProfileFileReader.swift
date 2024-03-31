//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 3/30/24.
//

import Foundation

protocol ProfileFileReader {
    func read() -> AsyncStream<String>
}

// Reads the entire file once. Designed for reading the fully generated profile
class FullProfileFileReader: ProfileFileReader {
    private let fileProvider: FileContentProvider

    init(fileProvider: FileContentProvider) {
        self.fileProvider = fileProvider
    }

    func read() -> AsyncStream<String> {
        return AsyncStream { continuation in
            // TODO: implement reading from file efficiently
            do {
                let fileContent = try fileProvider.getContent()
                fileContent.enumerateLines { line, stop in
                    continuation.yield(line)
                }
                continuation.finish()
            } catch {
                print("error: \(error)")
                continuation.finish()
            }
        }
    }
}

