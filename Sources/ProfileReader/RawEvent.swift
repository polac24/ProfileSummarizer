//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 3/30/24.
//

import Foundation

// Struct representing the event represented in the json porofile
struct RawEvent: Decodable, Equatable {
    // Process id
    let pid: Int
    // Thread id
    // in some really rare cases (critical paths) tid is passed in `"args":{"tid":22868}`
    let tid: Int
    // ??
    let ph: String
    // category
    let cat: String?
    // name
    let name: String?
    // category name
    let cname: String?
    // duration in microseconds
    let dur: Int?
    // starting timestamp us)
    let ts: Int?
    // optional args, e.g. "name":"Critical Path"
    let args: [String: String]?
}
