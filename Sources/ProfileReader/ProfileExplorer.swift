//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 3/30/24.
//

import Foundation

enum ProfileExplorerMode {
    // Reading a single profile that is already fully generated
    case fullFile(path: String)
}

// The main class responsible to read the profile and parse it to the internal model
class ProfileExplorer {
    private let fileURL: URL
    private let profileReader: ProfileFileReader

    init(path: String, mode: ProfileExplorerMode) {
        let fileURL = URL(fileURLWithPath: path)
        self.fileURL = fileURL
        let fileProvider = JsonFileContentProvider(file: fileURL)
        self.profileReader = FullProfileFileReader(fileProvider: fileProvider)
        
    }
}
