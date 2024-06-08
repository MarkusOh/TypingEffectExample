//
//  BlurEffectView.swift
//  TypingEffectExample
//
//  Created by Seungsub Oh on 6/8/24.
//

import SwiftUI

struct BlurEffectView: UIViewRepresentable {
    let effect: UIBlurEffect
    
    func makeUIView(context: Context) -> some UIView {
        UIVisualEffectView(effect: effect)
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
