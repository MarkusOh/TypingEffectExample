//
//  ContentView.swift
//  TypingEffectExample
//
//  Created by Seungsub Oh on 5/25/24.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.showError) var showError
    @State var diskManager = DiskManager()
    
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
    static var recordingTask: Task<Void, Error>?
    
    let renderWidth = 1920.0
    let renderHeight = 1080.0
    
    @State var displayableTexts = [UniqueText]()
    @State var isRecording = false
    @State var result: URL?
    @State var data = """
                      당신은 사랑받기 위해 태어난 사람
                      당신의 삶속에서 그 사랑 받고 있지요
                      """
    
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
        NavigationStack {
            previewWindow
                .padding(5)
                .overlay(alignment: .trailing) {
                    buttonArray
                }
                .background(Color.black, ignoresSafeAreaEdges: .all)
                .sheet(item: $result) { videoResult in
                    ShareView(sharable: videoResult)
                }
        }
    }
    
    var buttonArray: some View {
        VStack {
            setTextButton
            startAnimatingButton
            captureImageButton
            startRecordingButton
        }
        .fixedSize()
        .buttonStyle(CustomButtonStyle())
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
    
    var setTextButton: some View {
        NavigationLink("Set Text to Animate") {
            SetTextToAnimateView(textToAnimate: $data)
        }
    }
    
    var startAnimatingButton: some View {
        Button("Start Animating", action: startAnimating)
    }
    
    var captureImageButton: some View {
        Button("Capture Image") {
            Task { @MainActor in
                guard let image = imageRenderer.uiImage,
                      let transparentImageData = image.pngData(),
                      let transparentImage = UIImage(data: transparentImageData) else {
                    return
                }
                
                UIImageWriteToSavedPhotosAlbum(transparentImage, nil, nil, nil)
            }
        }
    }
    
    var startRecordingButton: some View {
        Button("\(isRecording ? "Stop" : "Start") Recording") {
            guard isRecording == false else {
                stopAnimating()
                stopRecording()
                return
            }
            
            startRecording()
            startAnimating()
        }
    }
    
    func startAnimating() {
        stopAnimating()
        index = 0
        set(text: "")
        
        Self.animationTask = Task {
            var trackedString = ""
            
            do {
                try await Task.sleep(for: .milliseconds(500))
            } catch is CancellationError {
                return
            }
            
            for char in Array(data) {
                let scalar = char.unicodeScalars
                let uInt = scalar[scalar.startIndex].value
                for character in disassembleUnicode(uInt) {
                    do {
                        if character == "\n" {
                            try await Task.sleep(for: .milliseconds(500))
                        } else {
                            try await Task.sleep(for: .milliseconds(50))
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
            
            do {
                try await Task.sleep(for: .milliseconds(500))
            } catch is CancellationError {
                return
            }
            
            isRecording = false
        }
    }
    
    func startRecording() {
        isRecording = true
        let errorTitle = "Recording Error"
        
        Self.recordingTask = Task { @MainActor in
            do {
                try diskManager.resetSubdirectory()
            } catch {
                showError(errorTitle, error)
                return
            }
            
            while isRecording {
                if let image = imageRenderer.uiImage,
                   let imageData = image.pngData() {
                    do {
                        try diskManager.save(imageData: imageData)
                    } catch {
                        showError(errorTitle, error)
                        return
                    }
                }
                
                do {
                    try await Task.sleep(for: .microseconds(16_666.67))
                } catch is CancellationError {
                    return
                }
            }
            
            let url: URL
            do {
                url = try await diskManager.createVideo()
            } catch {
                showError(errorTitle, error)
                return
            }
            
            result = url
        }
    }
    
    func stopAnimating() {
        Self.animationTask?.cancel()
        Self.animationTask = nil
    }
    
    func stopRecording() {
        Self.recordingTask?.cancel()
        Self.recordingTask = nil
        isRecording = false
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
}

#Preview {
    ContentView()
}
