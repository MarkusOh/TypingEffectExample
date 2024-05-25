//
//  ContentView.swift
//  TypingEffectExample
//
//  Created by Seungsub Oh on 5/25/24.
//

import SwiftUI

struct ContentView: View {
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
    
    var body: some View {
        GeometryReader { proxy in
            Text(text)
                .font(.title)
                .padding()
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                .overlay(alignment: .bottom) {
                    Button("Start Animating") {
                        Task {
                            var trackedString = ""
                            
                            for char in Array("안녕하세요 저는 오승섭입니다.\nThings are here for good") {
                                let scalar = char.unicodeScalars
                                let uInt = scalar[scalar.startIndex].value
                                for character in disassembleUnicode(uInt) {
                                    
                                    try? await Task.sleep(for: .seconds(0.2))
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

#Preview {
    ContentView()
}
