//
//  ProfileLineConsumer.swift
//  
//
//  Created by Bartosz Polaczyk on 3/30/24.
//

import Foundation


public protocol ProfileStateProvider {
    var profileContext: BazelContext? { get }
    var state: ProfileLineParserState { get }
}
