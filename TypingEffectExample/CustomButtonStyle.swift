//
//  CustomButtonStyle.swift
//  TypingEffectExample
//
//  Created by Seungsub Oh on 6/8/24.
//

import SwiftUI

struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(6)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .background(BlurEffectView(effect: UIBlurEffect(style: .systemMaterial)))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}
