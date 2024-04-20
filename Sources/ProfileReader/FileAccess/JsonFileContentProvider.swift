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
        let observer = try CompleteFileObserver(url: file)
        return AsyncStream<String>{ continuation in
            do {
                try observer.start { event in
                    switch event {
                    case .line(let input):
                        continuation.yield(input)
                    case .start:
                        continuation.finish()
                    case .finish:
                        continuation.finish()
                    }
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

