//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 4/6/24.
//

import Foundation

enum FileObserverError: Error {
    case alreadyStarted
}

// This class is not thread safe
final class FileObserver {
    static let defaultQueue = DispatchQueue(label: "FileObserverDefaultQueue")
    static let defaultEvents: DispatchSource.FileSystemEvent = [.extend, .write]
    let url: URL
    private var source: DispatchSourceFileSystemObject?
    private let events: DispatchSource.FileSystemEvent
    private let queue: DispatchQueue

    init(url: URL,
         events: DispatchSource.FileSystemEvent = defaultEvents,
         queue: DispatchQueue = FileObserver.defaultQueue
    ) throws {
        self.url = url
        self.events = events
        self.queue = queue
    }

    // Warning: this function is not thread safe
    func start(action: @escaping (String) -> ()) throws {
        guard source == nil else {
            throw FileObserverError.alreadyStarted
        }
        let fileHandle = try FileHandle(forReadingFrom: url)
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileHandle.fileDescriptor,
            eventMask: events,
            queue: queue
        )

        // call with the initial data first
        if let initialData = process(fileHandle: fileHandle, event: .write), !initialData.isEmpty {
            queue.async {
                action(initialData)
            }
        }
        source.setEventHandler { [weak self] in
            let event = source.data
            if let read = self?.process(fileHandle: fileHandle, event: event) {
                action(read)
            }
        }
        source.setCancelHandler {
            try? fileHandle.close()
        }
        source.resume()
        self.source = source
    }

    deinit {
        guard let source = source else {
           return
        }
        source.cancel()
    }

    // process writing events and extracts associated data wrote to the file
    private func process(fileHandle: FileHandle, event: DispatchSource.FileSystemEvent) -> String? {
        guard event.contains(.extend) || event.contains(.write) else {
            return nil
        }
        let newData = fileHandle.readDataToEndOfFile()
        let string = String(data: newData, encoding: .utf8)!
        return string
    }
}
