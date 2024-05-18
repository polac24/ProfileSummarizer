// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import ProfileReader


guard let inputFile = ProcessInfo.processInfo.arguments.dropFirst().first else {
    print("Missing profile path")
    exit(1)
}

let parser = ProfileLineParser()
let exporter = ProfileExplorer(path: inputFile, mode: .fullFile(path: inputFile), parser: parser)
let semphore = DispatchSemaphore(value: 0)
Task {
    let stream = exporter.startOnBazelAction()
    for try await contextErased in stream {
        // TODO: make type-safe for performance
        guard let context = contextErased as? ProfileContext else {
            continue
        }
        print(context.actions.last!)
    }
    semphore.signal()
}

semphore.wait()



extension ProfileExplorer {
    func startOnBazelAction() -> any AsyncSequence {
        var observedActions: [BazelAction] = []
        return start().filter { context in
            defer {
                observedActions = context.actions
            }
            return observedActions != context.actions
        }
    }
}

