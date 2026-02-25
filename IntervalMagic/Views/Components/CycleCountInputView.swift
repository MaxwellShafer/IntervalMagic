//
//  CycleCountInputView.swift
//  IntervalMagic
//

import SwiftUI

struct CycleCountInputView: View {
    @Binding var cycleMode: CycleMode

    @State private var text: String

    init(cycleMode: Binding<CycleMode>) {
        _cycleMode = cycleMode
        _text = State(initialValue: cycleMode.wrappedValue.cycleCountValue.map(String.init) ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    decrement()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderless)

                TextField("0", text: $text)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 72)
                    .onChange(of: text) { _, newValue in
                        applyTextChange(newValue)
                    }

                Button {
                    increment()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderless)
            }

            Text("Leave blank or set to 0 to loop (infinite).")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onChange(of: cycleMode) { _, newValue in
            let desired = newValue.cycleCountValue.map(String.init) ?? ""
            if desired != text {
                text = desired
            }
        }
    }

    private func applyTextChange(_ raw: String) {
        let digits = raw.filter(\.isNumber)
        if digits != raw {
            text = digits
            return
        }

        guard !digits.isEmpty else {
            cycleMode = .infinite
            return
        }

        let n = Int(digits) ?? 0
        if n <= 0 {
            cycleMode = .infinite
        } else {
            cycleMode = .fixed(n)
        }
    }

    private func increment() {
        let n = Int(text) ?? 0
        let next = max(0, n) + 1
        text = String(next)
        cycleMode = .fixed(next)
    }

    private func decrement() {
        let n = Int(text) ?? 0
        if n <= 1 {
            text = ""
            cycleMode = .infinite
            return
        }
        let next = n - 1
        text = String(next)
        cycleMode = .fixed(next)
    }
}

