//
//  HidableText.swift
//  TypingEffectExample
//
//  Created by Seungsub Oh on 6/2/24.
//

import SwiftUI
import Observation

struct HidableText: View {
    var text: UniqueText
    
    @State private var isHidden = false
    
    var body: some View {
        Text(text.text)
            .opacity(isHidden ? 0 : 1)
            .overlay {
                GeometryReader { proxy in
                    checkHidden(frame: proxy.frame(in: .global))
                }
            }
    }
    
    func checkHidden(frame: CGRect) -> some View {
        if frame.maxY < 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isHidden = true
            }
        }
        
        return Color
            .clear
            .contentShape(Rectangle())
    }
}
