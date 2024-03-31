//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 3/30/24.
//

import Foundation

// Struct representing the preamble object
struct RawPreamble: Decodable, Equatable {
    enum CodingKeys: String, CodingKey {
        case otherData = "otherData"
    }
    struct OtherData: Decodable, Equatable {
        enum CodingKeys: String, CodingKey {
            case bazelVersion = "bazel_version"
            case buildId = "build_id"
            case date = "date"
            case profileFinishTs = "profile_finish_ts"
        }
        let bazelVersion: String
        // bazel invocation UUID
        let buildId: UUID
        // e.g. 2024-03-29T19:05:29.869613Z
        let date: Date
        // TODO: which finish is that? Is that available in "partial profile"?
        let profileFinishTs: Int
    }
    let otherData: OtherData
}

