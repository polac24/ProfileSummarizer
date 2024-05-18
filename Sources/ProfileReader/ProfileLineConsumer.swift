//
//  ProfileLineConsumer.swift
//  
//
//  Created by Bartosz Polaczyk on 3/30/24.
//

import Foundation

public struct ProfileContext: Equatable {
    public var profileContext: BazelContext?
    public var state: ProfileLineParserState
    public let actions: [BazelAction]
}

public protocol ProfileLineConsumer {
    // Called whenever a new line has been read from the profile
    func observed(newLine: String) -> ProfileContext
}
