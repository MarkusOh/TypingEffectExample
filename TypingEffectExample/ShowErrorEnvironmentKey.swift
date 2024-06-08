//
//  ShowErrorEnvironmentKey.swift
//  TypingEffectExample
//
//  Created by Seungsub Oh on 6/8/24.
//

import SwiftUI

struct ShowErrorEnvironmentKey: EnvironmentKey {
    static var defaultValue: (_ errorTitle: String, _ error: Error) -> Void = { _, _ in }
}

extension EnvironmentValues {
    var showError: (_ errorTitle: String, _ error: Error) -> Void  {
        get { self[ShowErrorEnvironmentKey.self] }
        set { self[ShowErrorEnvironmentKey.self] = newValue }
    }
}
