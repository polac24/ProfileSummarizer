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
let actionsFilter: BazelActionFilter = BazelActionFilterComposition(filters: [BazelActionFilterConfiguration.mode([.nonCacheable, .localCache])])
let actionSerializer: any ActionSerializer = OutputActionSerializer()
let actionPrinterBazelActionVisitor = ActionPrinterBazelActionVisitor(
    serializer: actionSerializer,
    filter: actionsFilter
    )

// wait for the stream to finish
let semaphore = DispatchSemaphore(value: 0)
Task {
    let stream = exporter.startOnBazelAction()
    for try await contextErased in stream {
        // TODO: make type-safe for performance
        guard let context = contextErased as? ProfileContext else {
            continue
        }
        // all new actions are attached as the last one
        // TODO: make better abstraction than the last
        guard let newAction = context.actions.last else {
            continue
        }
        actionPrinterBazelActionVisitor.visit(newAction)
    }
    semaphore.signal()
}

semaphore.wait()



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

