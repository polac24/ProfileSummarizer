//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 5/19/24.
//

import Foundation
import ProfileReader

public protocol ActionSerializer<OutputStream> {
    // The type of the serializer serializes to
    associatedtype OutputStream

    func serialize(_ action: BazelAction) -> OutputStream
}

public class OutputActionSerializer: ActionSerializer {

    public func serialize(_ action:BazelAction) -> String {
        return "\(action.name)|[\(action.target)]"
    }
}
