//
//  ContentView.swift
//  TypingEffectExample
//
//  Created by Seungsub Oh on 5/25/24.
//

import SwiftUI

struct ContentView: View {
    let writer: ImageAnimator = .init(renderSettings: .init())
    
    func set(text: String) {
        guard text.isEmpty == false else {
            displayableTexts = [UniqueText]()
            return
        }
        
        for (index, text) in Array(text.components(separatedBy: "\n").enumerated()) {
            if let displayable = displayableTexts[safe: index] {
                displayableTexts[index] = .init(id: displayable.id, text)
            } else {
                displayableTexts.append(.init(text))
            }
        }
    }
    
    @State private var index = 0
    static var animationTask: Task<Void, Error>?
    
    let renderWidth = 1920.0
    let renderHeight = 1080.0
    
    @State var displayableTexts = [UniqueText]()
    @State var isRecording = false
    
    var renderable: some View {
        VerticalCarousel(selectedIndex: index) {
            ForEach(displayableTexts) { text in
                HidableText(text: text)
            }
        }
        .font(.system(size: 60).bold())
        .frame(width: renderWidth, height: renderHeight)
        .foregroundStyle(Color.black)
        .background(Color.clear)
    }
    
    @MainActor
    var imageRenderer: ImageRenderer<some View> {
        ImageRenderer(content: renderable)
    }
    
    var body: some View {
        previewWindow
            .padding(5)
            .overlay(alignment: .bottom) {
                VStack {
                    startAnimatingButton
                    captureImageButton
                    startRecordingButton
                }
            }
            .background(Color.black, ignoresSafeAreaEdges: .all)
    }
    
    var previewWindow: some View {
        GeometryReader { proxy in
            let borderOffset = 14.0
            let renderWidth = renderWidth + borderOffset
            let renderHeight = renderHeight + borderOffset
            let adjustedAspectRatioWidth = (renderWidth / renderHeight) / (proxy.size.width / proxy.size.height)
            let adjustedAspectRatioHeight = (renderHeight / renderWidth) / (proxy.size.height / proxy.size.width)
            let adjustedWidth = proxy.size.width / renderWidth * (proxy.size.width > proxy.size.height ? adjustedAspectRatioWidth : 1)
            let adjustedHeight = proxy.size.height / renderHeight * (proxy.size.height > proxy.size.width ? adjustedAspectRatioHeight : 1)
            
            renderable
                .background(Color.white)
                .padding(borderOffset)
                .border(isRecording ? Color.red : .gray, width: borderOffset)
                .scaleEffect(x: adjustedWidth, y: adjustedHeight, anchor: .topLeading)
        }
    }
    
    var startAnimatingButton: some View {
        Button("Start Animating", action: startAnimating)
    }
    
    func startAnimating() {
        Self.animationTask?.cancel()
        Self.animationTask = nil
        index = 0
        set(text: "")
        
        Self.animationTask = Task {
            var trackedString = ""
            
            for char in Array(Self.data) {
                let scalar = char.unicodeScalars
                let uInt = scalar[scalar.startIndex].value
                for character in disassembleUnicode(uInt) {
                    do {
                        if character == "\n" {
                            try await Task.sleep(for: .seconds(0.2))
                        } else {
                            try await Task.sleep(for: .seconds(0.025))
                        }
                    } catch is CancellationError {
                        return
                    }
                    
                    if character == "\n" {
                        withAnimation {
                            index += 1
                        }
                    }
                    
                    trackedString += "\(character)"
                    set(text: trackedString)
                }
            }
            
            isRecording = false
        }
    }
    
    var captureImageButton: some View {
        Button("Capture Image") {
            Task { @MainActor in
                guard let image = imageRenderer.uiImage ,
                      let transparentImageData = image.pngData(),
                      let transparentImage = UIImage(data: transparentImageData) else {
                    return
                }
                
                UIImageWriteToSavedPhotosAlbum(transparentImage, nil, nil, nil)
            }
        }
    }
    
    var startRecordingButton: some View {
        Button("Start Recording") {
            guard isRecording == false else {
                return
            }
            
            isRecording = true
            startAnimating()
            
            Task { @MainActor in
                while isRecording {
                    if let image = imageRenderer.uiImage ,
                       let transparentImageData = image.pngData(),
                       let transparentImage = UIImage(data: transparentImageData) {
                        writer.images.append(transparentImage)
                    }
                    
                    try? await Task.sleep(for: .seconds(1 / 60))
                }
                
                do {
                    try await writer.render()
                } catch {
                    print("Image Writer has responded with error \(error.localizedDescription)")
                }
            }
        }
    }
}

extension ContentView {
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
    
    static let data = """
                      당신은 사랑받기 위해 태어난 사람
                      당신의 삶속에서 그 사랑 받고 있지요
                      당신은 사랑 받기 위해 태어난 사람
                      지금도 그 사랑 받고 있지요
                      """
}

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
            let size = upperSubview.sizeThatFits(proposal)
            let nextHeight = subviews[safe: index + 1]?.sizeThatFits(proposal).height ?? .zero
            y -= (size.height / 2 + nextHeight / 2)
        }
        
        // place each subview in vertical order
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(proposal)
            subview.place(at: .init(x: bounds.minX, y: y + bounds.maxY), anchor: .bottomLeading, proposal: proposal)
            
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
