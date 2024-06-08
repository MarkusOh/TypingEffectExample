//
//  URL+Identifiable.swift
//  TypingEffectExample
//
//  Created by Seungsub Oh on 6/8/24.
//

import Foundation

extension URL: Identifiable {
    public var id: String {
        self.absoluteString
    }
}
