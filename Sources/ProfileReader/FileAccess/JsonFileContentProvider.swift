//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 3/31/24.
//

import Foundation

// Reading the not compressed raw profile in the json format
class JsonFileContentProvider: FileContentProvider {
    var supportsAsync: Bool = true

    func getContentAsync() throws -> AsyncStream<String> {
        let observer = try FileObserver(url: file)
        return AsyncStream<String>{ continuation in
            do {
                try observer.start { input in
                    continuation.yield(input)
                }
            } catch {
                // finishes only on error
                continuation.finish()
            }
        }
    }


    let file: URL
    init(file: URL) {
        self.file = file
    }

    func getContent() throws -> String {
        try String(contentsOf: file)
    }
}

