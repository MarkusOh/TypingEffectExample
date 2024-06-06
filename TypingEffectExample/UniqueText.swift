//
//  UniqueText.swift
//  TypingEffectExample
//
//  Created by Seungsub Oh on 6/6/24.
//

import Foundation
import Observation

@Observable
class UniqueText: Identifiable {
    let id: UUID = .init()
    var text: String
    
    init(_ text: String) {
        self.text = text
    }
}
