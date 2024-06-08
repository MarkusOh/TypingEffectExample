//
//  TypingEffectExampleApp.swift
//  TypingEffectExample
//
//  Created by Seungsub Oh on 5/25/24.
//

import SwiftUI

@main
struct TypingEffectExampleApp: App {
    @State var errorWrapper: ErrorWrapper?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.showError) { errorTitle, error in
                    errorWrapper = ErrorWrapper(errorTitle: errorTitle, error: error)
                }
                .alert(item: $errorWrapper) { errorWrapper in
                    Alert(title: Text(errorWrapper.errorTitle),
                          message: Text(errorWrapper.error.localizedDescription),
                          dismissButton: .cancel())
                }
        }
    }
}
