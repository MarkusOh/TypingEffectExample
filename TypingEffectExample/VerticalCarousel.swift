//
//  VerticalCarousel.swift
//  TypingEffectExample
//
//  Created by Seungsub Oh on 6/8/24.
//

import SwiftUI

struct VerticalCarousel: Layout {
    var selectedIndex: Int
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = 0.0
        let proposal: ProposedViewSize = .init(width: bounds.width, height: bounds.height)
        
        // get initial y placement
        for (index, upperSubview) in subviews.prefix(upTo: selectedIndex).enumerated() {
            let nextHeight = subviews[safe: index + 1]?.sizeThatFits(proposal).height ?? .zero
            y -= nextHeight
        }
        
        // place each subview in vertical order
        for (index, subview) in subviews.enumerated() {
            subview.place(at: .init(x: bounds.minX, y: y + bounds.maxY), anchor: .bottomLeading, proposal: proposal)
            let nextHeight = subviews[safe: index + 1]?.sizeThatFits(proposal).height ?? .zero
            y += nextHeight
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
