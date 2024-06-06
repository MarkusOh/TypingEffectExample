//
//  UniqueText.swift
//  TypingEffectExample
//
//  Created by Seungsub Oh on 6/6/24.
//

import Foundation

struct UniqueText: Identifiable {
    let id: UUID
    var text: String
    
    init(id: UUID = .init(), _ text: String) {
        self.id = id
        self.text = text
    }
}
