//
//  CompletionView.swift
//  IntervalMagic Watch App
//

import SwiftUI

struct CompletionView: View {
    let onRestart: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Done")
                .font(.headline)
            Button("Restart", action: onRestart)
            Button("Close", action: onClose)
        }
        .padding()
    }
}
