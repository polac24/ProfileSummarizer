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
    let stream = exporter.start()
    for await context in stream {
        print(context)
    }
    semphore.signal()
}

semphore.wait()


