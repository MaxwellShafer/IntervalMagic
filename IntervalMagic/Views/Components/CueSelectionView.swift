//
//  CueSelectionView.swift
//  IntervalMagic
//

import SwiftUI

struct CueSelectionView: View {
    @Binding var cueType: CueType

    private var hapticSelection: HapticStyle? {
        get {
            switch cueType {
            case .none, .sound: return nil
            case .haptic(let h): return h
            case .both(let h, _): return h
            }
        }
        set {
            let s = soundSelection
            if let h = newValue {
                cueType = s.map { .both(h, $0) } ?? .haptic(h)
            } else {
                cueType = s.map { .sound($0) } ?? .none
            }
        }
    }

    private var soundSelection: SoundStyle? {
        get {
            switch cueType {
            case .none, .haptic: return nil
            case .sound(let s): return s
            case .both(_, let s): return s
            }
        }
        set {
            let h = hapticSelection
            if let s = newValue {
                cueType = h.map { .both($0, s) } ?? .sound(s)
            } else {
                cueType = h.map { .haptic($0) } ?? .none
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cue")
                .font(.headline)

            HStack {
                Picker("Haptic", selection: Binding(
                    get: { hapticSelection },
                    set: { hapticSelection = $0 }
                )) {
                    Text("None").tag(nil as HapticStyle?)
                    ForEach(HapticStyle.allCases, id: \.self) { style in
                        Text(style.rawValue.capitalized).tag(style as HapticStyle?)
                    }
                }
                .pickerStyle(.menu)
                if hapticSelection != nil {
                    Button("Preview") {
                        HapticCueService.shared.play(cueType: cueType)
                    }
                    .font(.caption)
                }
            }

            HStack {
                Picker("Sound", selection: Binding(
                    get: { soundSelection },
                    set: { soundSelection = $0 }
                )) {
                    Text("None").tag(nil as SoundStyle?)
                    ForEach(SoundStyle.allCases, id: \.self) { style in
                        Text(style.rawValue.capitalized).tag(style as SoundStyle?)
                    }
                }
                .pickerStyle(.menu)
                if soundSelection != nil {
                    Button("Preview") {
                        SoundCueService.shared.play(cueType: cueType)
                    }
                    .font(.caption)
                }
            }
        }
    }
}
