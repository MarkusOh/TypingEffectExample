//
//  ContentView.swift
//  TypingEffectExample
//
//  Created by Seungsub Oh on 5/25/24.
//

import SwiftUI

struct ContentView: View {
    // This function is inspired and copied by the velog.io post from URL https://velog.io/@heunb/Korean-Typo-animation
    func disassembleUnicode(_ char: UInt32) -> [UnicodeScalar] {
        // Guard against non-Korean characters and out of range values
        guard (0xAC00...0xD7A3).contains(char) else {
            return [UnicodeScalar(char)!] // Return as-is if non-Korean character
        }
        
        let x = (char - 0xac00) / 28 / 21
        let y = (char - 0xac00) / 28 % 21
        let z = (char - 0xac00) % 28
        
        let initial = UnicodeScalar(0x1100 + x)// 초성
        let neuter = UnicodeScalar(0x1161 + y)// 중성
        let final = UnicodeScalar(0x11a7 + z)// 종성
        
        var arr = [initial, neuter, final].compactMap { $0 }
        
        if final == UnicodeScalar(0x11A7) { //받침 없음
            arr.removeLast()
        }
        
        return arr
    }
    
    @State private var text = ""
    @State private var index = 0
    
    var body: some View {
        GeometryReader { proxy in
            VerticalCarousel(selectedIndex: index) {
                ForEach(Array(text.components(separatedBy: "\n").enumerated()), id: \.offset) { (eachIndex, eachText) in
                    Text(eachText)
                        .scaleEffect(eachIndex == index ? 1 : 0.5, anchor: .leading)
                }
            }
                .font(.system(size: 60).bold())
                .padding()
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                .overlay(alignment: .bottom) {
                    Button("Start Animating") {
                        Task {
                            var trackedString = ""
                            
                            for char in Array(
                            """
                            
                            """) {
                                let scalar = char.unicodeScalars
                                let uInt = scalar[scalar.startIndex].value
                                for character in disassembleUnicode(uInt) {
                                    if character == "\n" {
                                        try? await Task.sleep(for: .seconds(0.5))
                                    } else {
                                        try? await Task.sleep(for: .seconds(0.025))
                                    }
                                    
                                    if character == "\n" {
                                        withAnimation {
                                            index += 1
                                        }
                                    }
                                    
                                    trackedString += "\(character)"
                                    text = trackedString
                                }
                            }
                        }
                    }
                }
        }
    }
}

struct VerticalCarousel: Layout {
    var selectedIndex: Int
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let selectedIndex = Self.clamp(value: selectedIndex, to: 1...subviews.count)
        var y = 0.0
        let proposal: ProposedViewSize = .init(width: bounds.width, height: bounds.height)
        
        // get initial y placement
        for (index, upperSubview) in subviews.prefix(upTo: selectedIndex - 1).enumerated() {
            let size = upperSubview.sizeThatFits(proposal)
            let nextHeight = subviews[safe: index + 1]?.sizeThatFits(proposal).height ?? .zero
            y -= (size.height / 2 + nextHeight / 2)
        }
        
        // place each subview in vertical order
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(proposal)
            subview.place(at: .init(x: bounds.minX, y: y + bounds.midY), anchor: .leading, proposal: proposal)
            
            let nextHeight = subviews[safe: index + 1]?.sizeThatFits(proposal).height ?? .zero
            y += (size.height / 2 + nextHeight / 2)
        }
    }
    
    static func clamp(value: Int, to limits: ClosedRange<Int>) -> Int {
        return min(max(value, limits.lowerBound), limits.upperBound)
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ContentView()
}
