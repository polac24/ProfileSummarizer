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

enum FileObserverEvent {
    case start
    case line(String)
    case finish
}

protocol FileObserver {
    func start(action: @escaping (FileObserverEvent) -> ()) throws
}

// Observes files changes in the append and write mode
// Warning! This class is not thread safe
final class CompleteFileObserver: FileObserver {
    static let defaultQueue = DispatchQueue(label: "FileObserverDefaultQueue")
    static let defaultEvents: DispatchSource.FileSystemEvent = [.extend, .write]
    let url: URL
    private var source: DispatchSourceFileSystemObject?
    private let events: DispatchSource.FileSystemEvent
    private let queue: DispatchQueue
    // Keep dirObserver to support writing to a file (not expanding)
    private let dirObserver: DirObserver

    init(url: URL,
         events: DispatchSource.FileSystemEvent = defaultEvents,
         queue: DispatchQueue = CompleteFileObserver.defaultQueue
    ) throws {
        self.url = url
        self.events = events
        self.queue = queue
        try dirObserver = DirObserver(
            dirURL: url.deletingLastPathComponent(), 
            observationFileURL: url,
            events: [.write],
            queue: queue
        )
    }

    // Warning: this function is not thread safe
    func start(action: @escaping (FileObserverEvent) -> ()) throws {
        guard source == nil else {
            throw FileObserverError.alreadyStarted
        }

        self.source = try setupSource(for: action)
        try dirObserver.start { [weak self] oldState, newState in
            // a new write has happened


            // restart the observation as a file hander needs to be assigned
            self?.source?.cancel()
            do {
                self?.source = try self?.setupSource(for: action)
            } catch {
                print("error: restarting new file observation after a write has failed: \(error)")
            }
        }
    }

    deinit {
        guard let source = source else {
           return
        }
        source.cancel()
    }

    private func setupSource(for action: @escaping (FileObserverEvent) -> ()) throws -> DispatchSourceFileSystemObject? {
        // TODO: check for already started

        let fileHandle = try FileHandle(forReadingFrom: url)
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileHandle.fileDescriptor,
            eventMask: events,
            queue: queue
        )
        // call with the initial data first
        if let initialData = process(fileHandle: fileHandle, event: .write), !initialData.isEmpty {
            queue.async {
                action(.line(initialData))
            }
        }
        source.setEventHandler { [weak self] in
            let event = source.data
            if let read = self?.process(fileHandle: fileHandle, event: event) {
                action(.line(read))
            }
        }
        source.setCancelHandler {
            try? fileHandle.close()
        }
        source.resume()
        return source
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
