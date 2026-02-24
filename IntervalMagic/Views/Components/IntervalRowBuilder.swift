//
//  IntervalRowBuilder.swift
//  IntervalMagic
//

import SwiftUI

struct IntervalRowBuilder: View {
    let interval: Interval
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(interval.name)
                    .font(.headline)
                Text("\(interval.durationSeconds)s · \(cueDescription)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                Button("Edit", action: onEdit)
                Button("Duplicate", action: onDuplicate)
                Button("Delete", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
    }

    private var cueDescription: String {
        switch interval.cueType {
        case .haptic(let h): return "Haptic \(h.rawValue)"
        case .sound(let s): return "Sound \(s.rawValue)"
        case .both(let h, let s): return "\(h.rawValue) + \(s.rawValue)"
        }
    }
}
