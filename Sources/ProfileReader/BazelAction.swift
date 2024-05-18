//
//  File.swift
//
//
//  Created by Bartosz Polaczyk on 3/30/24.
//

import Foundation

public struct BazelAction: Equatable {
    let name: String
    let target: String?
    let cacheResult: BazelCacheResult
    let startingTimestampMicros: Int
    let endingTimestampMicros: Int
    let `internal`: Bool
}

extension BazelAction {
    var durationMicro: Int {
        endingTimestampMicros - startingTimestampMicros
    }
}

extension BazelAction {
    static func from(_ state: ProfileLineParserState) -> Self? {
        guard let name = state.name, let startsMicro = state.startingTimestamp, let endingTimestamp = state.endingTimestamp else {
            return nil
        }
        let target = extractBazelTargetFrom(actionName: name)
        // Internal actions have at max 4 subactions
        let isInternal = state.subEvents.count <= 4

        return Self(
            name: name,
            target: target,
            cacheResult: state.cacheResult,
            startingTimestampMicros: startsMicro,
            endingTimestampMicros: endingTimestamp,
            internal: isInternal
        )
    }

    private static func extractBazelTargetFrom(actionName: String) -> String? {
        do {
            let regex = #/(@\w+)?//([^: ]+)(:(\w+))?/#
            guard let matchString = try regex.firstMatch(in: actionName)?.output.0 else {
                return nil
            }
            return String(matchString)
        } catch {
            print("error: \(error)")
        }
        return nil
    }
}
