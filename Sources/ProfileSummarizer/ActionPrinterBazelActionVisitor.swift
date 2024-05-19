//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 5/19/24.
//

import Foundation
import ProfileReader

public class ActionPrinterBazelActionVisitor: BazelActionVisitor {
    let serializer: any ActionSerializer
    let filter: BazelActionFilter

    public init(serializer: any ActionSerializer, filter: BazelActionFilter) {
        self.serializer = serializer
        self.filter = filter
    }

    public func visit(_ action: ProfileReader.BazelAction) {
        guard filter.filter(action) else {
            return
        }
        print(serializer.serialize(action))
    }
}
