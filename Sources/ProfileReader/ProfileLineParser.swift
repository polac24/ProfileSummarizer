//
//  ProfileReader.swift
//
//
//  Created by Bartosz Polaczyk on 3/30/24.
//

import Foundation

enum BazelCacheResult {
    // when the action was cacheable, but had a cache miss
    case miss
    // an action had disabled cacheable
    case noncacheable
    // cache hit from disk/memory
    case local
    // cache hit from remote
    case remote
}

// Machine state for parsing all events and generating a set of Actions
public final class ProfileLineParser: ProfileLineConsumer {

    // internal implementation of the current action exploring
    struct State {
        var name: String?
        var cacheResult: BazelCacheResult?

        func transform(_ newEvent: RawEvent) -> State {
            // TODO: implement the state machine
            return self
        }
    }

    private(set) var profileContext: BazelContext?
    private(set) var actions: [BazelAction] = []
    private(set) var state: State = State()
    private let decoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom({ (d: any Decoder) in
            let dateString = try d.singleValueContainer().decode(String.self)
            // TODO: implement reading from dateString
            return Date()
        })
        return decoder
    }()
    private (set) var errors: [Error] = []

    func observed(newLine: String) {
        guard let jsonLine = extractJsonObject(rawLine: newLine) else {
            return
        }
        let strippedJsonString = jsonLine.trimmingCharacters(in: .whitespaces)
        guard !strippedJsonString.isEmpty else {
            return
        }
        do {
            try consume(jsonString: jsonLine)
        } catch {
            print("Failed to parse event of preamble: \(newLine), reduced to \(strippedJsonString). Error: \(error)")
            errors.append(error)
        }
    }

    private func consume(jsonString: any StringProtocol) throws {
        do {
            // majority of jsons will be events, so optimistically trying first that format
            let event = try decoder.decode(RawEvent.self, from: jsonString.data(using: .utf8)!)
            state = state.transform(event)
        } catch {
            let preamble = try decoder.decode(RawPreamble.self, from: jsonString.data(using: .utf8)!)
            profileContext = try BazelContext.build(from: preamble)
        }
    }
}

// Extra helper methods that could be extracted to a separate class
extension ProfileLineParser {
    private func extractJsonObject(rawLine: String) -> (any StringProtocol)? {
        switch rawLine.last {
        case .none:
            // empty line
            return nil
        case ",":
            // probably an event in the `traceEvents` array
            return rawLine.dropLast(1)
        case "[":
            // The preamble line that starts "traceEvents" (so closing otherData.traceEvents)
            return rawLine.appending("]}")
        case "}", "]":
            // the closing brackets in the `traceEvents`
            return rawLine.dropLast(1)
        default:
            return rawLine
        }

    }
}
