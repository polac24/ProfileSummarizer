//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 4/9/24.
//

import Foundation

enum FileState: Equatable {
    case nonExisting
    case exists(inode: UInt64, size: UInt64)
    case error

    static func build(for url: URL, using fileManager: FileManager) throws -> Self {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        switch (attributes[.systemFileNumber] as? UInt64, attributes[.size] as? UInt64) {
        case let (.some(inode), .some(size)): return .exists(inode: inode, size: size)
        default: return .nonExisting
        }
    }
}

class DirObserver {
    private let dirURL: URL
    private let observationFileURL: URL
    private var source: DispatchSourceFileSystemObject?
    private let events: DispatchSource.FileSystemEvent
    private let queue: DispatchQueue
    private var action: ((FileState, FileState) -> ())?
    private var fileState: FileState {
        didSet {
            guard oldValue != fileState else { return }
            self.action?(oldValue, fileState)
        }
    }
    private let fileManager: FileManager

    init(dirURL: URL,
         observationFileURL: URL,
         events: DispatchSource.FileSystemEvent,
         queue: DispatchQueue,
         fileManager: FileManager = .default
    ) throws {
        self.dirURL = dirURL
        self.observationFileURL = observationFileURL
        self.events = events
        self.queue = queue
        self.fileManager = fileManager
        fileState = try FileState.build(for: observationFileURL, using: fileManager)
    }

    deinit {
        guard let source = source else {
           return
        }
        source.cancel()
    }

    func start(action: @escaping (FileState, FileState) -> ()) throws {
        guard source == nil else {
            throw FileObserverError.alreadyStarted
        }
        self.action = action

        fileState = try FileState.build(for: observationFileURL, using: fileManager)
        let fileDescriptor = open(dirURL.path, O_EVTONLY)
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.all],
            queue: queue
        )
        source.setEventHandler { [weak self] in
            self?.process(fileDescriptor: fileDescriptor, event: source.data)
        }
        source.setCancelHandler {
            close(fileDescriptor)
        }
        source.resume()
        self.source = source
    }

    // processes all events in a dir descriptor
    private func process(fileDescriptor: Int32, event: DispatchSource.FileSystemEvent) {
        guard event.contains(.write) else {
            return
        }
        do {
            // check if the file's size has changed because the write might event might come
            // from a different file in a dir
            // warning: if a write happened with the same size - the change might be ignored
            fileState = try FileState.build(for: observationFileURL, using: fileManager)
        } catch {
            fileState = .error
        }
    }
}
