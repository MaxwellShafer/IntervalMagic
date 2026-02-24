//
//  CueSelectionView.swift
//  IntervalMagic
//

import SwiftUI

struct CueSelectionView: View {
    @Binding var cueType: CueType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cue type")
                .font(.headline)

            Picker("Cue", selection: Binding(
                get: { cueKind },
                set: { cueKind = $0; applyCueKind() }
            )) {
                Text("Haptic only").tag(0)
                Text("Sound only").tag(1)
                Text("Both").tag(2)
            }
            .pickerStyle(.segmented)

            switch cueKind {
            case 0:
                hapticStylePicker(hapticBinding: Binding(
                    get: { hapticFromCue },
                    set: { cueType = .haptic($0) }
                ))
            case 1:
                soundStylePicker(soundBinding: Binding(
                    get: { soundFromCue },
                    set: { cueType = .sound($0) }
                ))
            case 2:
                hapticStylePicker(hapticBinding: Binding(
                    get: { bothHaptic },
                    set: { h in
                        let s = bothSound
                        cueType = .both(h, s)
                    }
                ))
                soundStylePicker(soundBinding: Binding(
                    get: { bothSound },
                    set: { s in
                        let h = bothHaptic
                        cueType = .both(h, s)
                    }
                ))
            default:
                EmptyView()
            }
        }
    }

    private var cueKind: Int {
        switch cueType {
        case .haptic: return 0
        case .sound: return 1
        case .both: return 2
        }
    }

    private func applyCueKind() {
        switch cueKind {
        case 0: cueType = .haptic(hapticFromCue)
        case 1: cueType = .sound(soundFromCue)
        case 2: cueType = .both(bothHaptic, bothSound)
        default: break
        }
    }

    private var hapticFromCue: HapticStyle {
        switch cueType {
        case .haptic(let h): return h
        case .both(let h, _): return h
        default: return .single
        }
    }

    private var soundFromCue: SoundStyle {
        switch cueType {
        case .sound(let s): return s
        case .both(_, let s): return s
        default: return .beep
        }
    }

    private var bothHaptic: HapticStyle {
        switch cueType {
        case .both(let h, _): return h
        default: return .single
        }
    }

    private var bothSound: SoundStyle {
        switch cueType {
        case .both(_, let s): return s
        default: return .beep
        }
    }

    private func hapticStylePicker(hapticBinding: Binding<HapticStyle>) -> some View {
        Picker("Haptic", selection: hapticBinding) {
            ForEach(HapticStyle.allCases, id: \.self) { style in
                Text(style.rawValue.capitalized).tag(style)
            }
        }
        .pickerStyle(.menu)
    }

    private func soundStylePicker(soundBinding: Binding<SoundStyle>) -> some View {
        Picker("Sound", selection: soundBinding) {
            ForEach(SoundStyle.allCases, id: \.self) { style in
                Text(style.rawValue.capitalized).tag(style)
            }
        }
        .pickerStyle(.menu)
    }
}
