//
//  SetTextToAnimateView.swift
//  TypingEffectExample
//
//  Created by Seungsub Oh on 6/8/24.
//

import SwiftUI

struct SetTextToAnimateView: View {
    @Binding var textToAnimate: String
    @FocusState var isFocused: Bool
    
    var body: some View {
        TextField("Text to Animate", text: $textToAnimate, axis: .vertical)
            .focused($isFocused)
            .lineLimit(5...10)
            .frame(height: 250)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            isFocused.toggle()
                        }
                    }
                }
            }
    }
}

#Preview {
    SetTextToAnimateView(textToAnimate: .constant(""))
}
