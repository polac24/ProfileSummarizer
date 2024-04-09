//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 3/30/24.
//

import Foundation

enum FileContentProviderError: Error {
    case invalidFormat(message: String)
}

// Reads the underlying file and generates the readable format
protocol FileContentProvider {
    // true when the async mode is supported
    var supportsAsync: Bool { get }
    func getContent() throws -> String
    func getContentAsync() throws -> AsyncStream<String>
}
