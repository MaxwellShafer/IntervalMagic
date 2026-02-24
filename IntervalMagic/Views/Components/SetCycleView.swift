//
//  SetCycleView.swift
//  IntervalMagic
//

import SwiftUI

struct SetCycleView: View {
    @Binding var cycleMode: CycleMode
    @Binding var fixedCycleCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(
                get: {
                    if case .infinite = cycleMode { return true }
                    return false
                },
                set: { isInfinite in
                    if isInfinite {
                        cycleMode = .infinite
                    } else {
                        cycleMode = .fixed(max(1, fixedCycleCount))
                    }
                }
            )) {
                Text("Loop (infinite)")
            }

            if case .fixed = cycleMode {
                HStack {
                    Button {
                        if fixedCycleCount > 1 {
                            fixedCycleCount -= 1
                            cycleMode = .fixed(fixedCycleCount)
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.borderless)

                    TextField("Cycles", value: $fixedCycleCount, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 60)
                        .onChange(of: fixedCycleCount) { _, newValue in
                            let n = max(1, newValue)
                            if n != fixedCycleCount { fixedCycleCount = n }
                            cycleMode = .fixed(n)
                        }

                    Button {
                        fixedCycleCount += 1
                        cycleMode = .fixed(fixedCycleCount)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var mode: CycleMode = .fixed(5)
        @State var count = 5
        var body: some View {
            SetCycleView(cycleMode: $mode, fixedCycleCount: $count)
                .padding()
        }
    }
    return PreviewWrapper()
}
