//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 3/30/24.
//

import Foundation

// Reads the underlying file and generates the readable format
protocol FileContentProvider {
    // TODO: consider async
    func getContent() throws -> String
}

// Reading the not compressed raw profile in the json format
class JsonFileContentProvider: FileContentProvider {
    
    let file: URL
    init(file: URL) {
        self.file = file
    }

    func getContent() throws -> String {
        try String(contentsOf: file)
    }
}
