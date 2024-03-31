//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 3/31/24.
//

import Foundation
import Gzip

// Reading the not compressed raw profile in the json format
class GzipFileContentProvider: FileContentProvider {

    let file: URL
    init(file: URL) {
        self.file = file
    }

    func getContent() throws -> String {
        let gunzippedData = try Data(contentsOf: file).gunzipped()

        guard let string = String(data: gunzippedData, encoding: .utf8) else {
            throw FileContentProviderError.invalidFormat(message: "gunzipped data is nil")
        }
        return string
    }
}
