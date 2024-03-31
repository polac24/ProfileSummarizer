//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 3/31/24.
//

import Foundation

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

