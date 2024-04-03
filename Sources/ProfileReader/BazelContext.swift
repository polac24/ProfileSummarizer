//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 3/30/24.
//

import Foundation

// Invocation details - available in the first line of the profile
struct BazelContext {
    let uuid: UUID
    let date: Date
}

extension BazelContext {
    static func build(from preamble: RawPreamble) throws -> Self {
        return BazelContext(uuid: UUID(), date: preamble.otherData.date)
    }
}
