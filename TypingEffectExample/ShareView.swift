//
//  ShareView.swift
//  TypingEffectExample
//
//  Created by Seungsub Oh on 6/8/24.
//

import SwiftUI

struct ShareView: UIViewControllerRepresentable {
    let sharable: URL
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        .init(activityItems: [sharable], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
