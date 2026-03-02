//
//  CueSelectionView.swift
//  IntervalMagic
//

import SwiftUI

struct CueSelectionView: View {
    @Binding var cueType: CueType
    private let store = CustomCuesStore.shared

    private var hapticSelection: HapticCue? {
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

    private var soundSelection: SoundCue? {
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

    private var hasCue: Bool {
        switch cueType {
        case .none: return false
        case .haptic, .sound, .both: return true
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cue")
                    .font(.headline)
                Spacer()
                if hasCue {
                    Button("Preview") {
                        HapticCueService.shared.play(cueType: cueType)
                        SoundCueService.shared.play(cueType: cueType)
                    }
                    .font(.caption)
                }
            }

            HStack {
                Picker("Haptic", selection: Binding(
                    get: { hapticSelection },
                    set: { newValue in
                        let s = soundSelection
                        if let h = newValue {
                            cueType = s.map { .both(h, $0) } ?? .haptic(h)
                        } else {
                            cueType = s.map { .sound($0) } ?? .none
                        }
                    }
                )) {
                    Text("None").tag(nil as HapticCue?)
                    ForEach(HapticStyle.allCases, id: \.self) { style in
                        Text(style.rawValue.capitalized).tag(HapticCue.predefined(style) as HapticCue?)
                    }
                    ForEach(store.customHaptics) { def in
                        Text(def.displayName).tag(HapticCue.custom(id: def.id) as HapticCue?)
                    }
                }
                .pickerStyle(.menu)
            }

            HStack {
                Picker("Sound", selection: Binding(
                    get: { soundSelection },
                    set: { newValue in
                        let h = hapticSelection
                        if let s = newValue {
                            cueType = h.map { .both($0, s) } ?? .sound(s)
                        } else {
                            cueType = h.map { .haptic($0) } ?? .none
                        }
                    }
                )) {
                    Text("None").tag(nil as SoundCue?)
                    ForEach(SoundStyle.allCases, id: \.self) { style in
                        Text(style.displayName).tag(SoundCue.predefined(style) as SoundCue?)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
}
