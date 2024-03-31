//
//  ProfileLineConsumer.swift
//  
//
//  Created by Bartosz Polaczyk on 3/30/24.
//

import Foundation


protocol ProfileLineConsumer {
    // Called whenever a new line has been read from the profile
    func observed(newLine: String)
}
