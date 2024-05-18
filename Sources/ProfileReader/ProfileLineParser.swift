//
//  ProfileReader.swift
//
//
//  Created by Bartosz Polaczyk on 3/30/24.
//

import Foundation

public enum ProfileLineParserError: Error {
    case invalidDateString(dateString: String)
}

public enum BazelCacheResult: Equatable {
    // when the action was cacheable, but had a cache miss
    case miss
    // an action had disabled cacheable
    case noncacheable
    // cache hit from disk/memory
    case local
    // cache hit from remote
    case remote
}

enum LogLevel: Int, Comparable {
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    case standard = 0
    case debug
}

// Implementation of the action exploring state machine
public struct ProfileLineParserState: Equatable {
    // Warning! This is just an approximation
    // If downloading for more than 10 us, the request was most likely taken
    // from the remote cache
    static let maxLocalDownloadingDuration = 10

    // TODO: Consider using just name
    struct SubEvent: Equatable {
        var name: String?
    }

    private(set) var name: String?
    private(set) var cacheResult: BazelCacheResult = .noncacheable
    private(set) var startingTimestamp: Int?
    private(set) var endingTimestamp: Int?
    private(set) var mnemonic: String?
    private(set) var subEvents: [SubEvent] = []

    func transform(_ newEvent: RawEvent) -> (Self, BazelAction?) {
        var newState = self

        if let mnemonic = newEvent.args?["mnemonic"] {
            if newState.mnemonic != nil {
                // TODO: report error - duplicated mnemonics
            }
            newState.mnemonic = mnemonic
            newState.name = newEvent.name
        }
        if let eventStart = newEvent.ts {
            newState.startingTimestamp = min(newState.startingTimestamp ?? .max, eventStart)
            if let eventDuration = newEvent.dur {
                newState.endingTimestamp = max(newState.endingTimestamp ?? .min, eventStart + eventDuration)
            }
        }
        newState.subEvents.append(SubEvent(name: newEvent.name))

        var foundAction: BazelAction? = nil
        switch newEvent.name {
        case "action.prepare":
            // starting a new event
            newState = Self()
        case "check cache hit":
            // this is cacheable
            newState.cacheResult = .miss
        case "download outputs":
            newState.cacheResult = .local
        case "Remote.download":
            guard let durationMicro = newEvent.dur else {
                //invalid format
                // TODO: report error
                break
            }
            let isDownloadingFromRemote = durationMicro > ProfileLineParserState.maxLocalDownloadingDuration
            newState.cacheResult = isDownloadingFromRemote ? .remote : .local
        case "postprocessing.run":
            // wrapping the entire
            foundAction = BazelAction.from(newState)
            newState = ProfileLineParserState()
        default:
            break
        }

        return (newState, foundAction)
    }
}

// Machine state for parsing all events and generating a set of Actions
public final class ProfileLineParser: ProfileLineConsumer {

    private let logLevel = LogLevel.standard
    private(set) var profileContext: BazelContext?
    private(set) var actions: [BazelAction] = []
    private(set) var state: ProfileLineParserState = ProfileLineParserState()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    private let decoder = {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        decoder.dateDecodingStrategy = .custom({ (d: any Decoder) in
            let dateString = try d.singleValueContainer().decode(String.self)
            guard let date = formatter.date(from: dateString) else {
                throw ProfileLineParserError.invalidDateString(dateString: dateString)
            }
            return date
        })
        return decoder
    }()
    private (set) var errors: [Error] = []

    public init(){}

    public func observed(newLine: String) -> ProfileContext {
        guard let jsonLine = extractJsonObject(rawLine: newLine) else {
            return ProfileContext(profileContext: profileContext, state: state, actions: actions)
        }
        let strippedJsonString = jsonLine.trimmingCharacters(in: .whitespaces)
        guard !strippedJsonString.isEmpty else {
            return ProfileContext(profileContext: profileContext, state: state, actions: actions)
        }
        do {
            try consume(jsonString: jsonLine)
        } catch {
            // TODO: parse different type of events, like memory
            if logLevel > LogLevel.debug {
                print("Failed to parse event of an event: \(newLine), reduced to \(strippedJsonString). Error: \(error)")
            }
            errors.append(error)
        }
        return ProfileContext(profileContext: profileContext, state: state, actions: actions)
    }

    private func consume(jsonString: any StringProtocol) throws {
        do {
            // majority of jsons will be events, so optimistically trying first that format
            let event = try decoder.decode(RawEvent.self, from: jsonString.data(using: .utf8)!)
            let (newState, newAction) = state.transform(event)
            state = newState
            if let action = newAction {
                actions.append(action)
            }
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
