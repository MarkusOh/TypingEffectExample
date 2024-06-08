//
//  ErrorWrapper.swift
//  TypingEffectExample
//
//  Created by Seungsub Oh on 6/8/24.
//

import Foundation

struct ErrorWrapper: Identifiable {
    var id: UUID = .init()
    let errorTitle: String
    let error: Error
}
