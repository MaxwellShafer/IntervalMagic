//
//  OptionsSheet.swift
//  IntervalMagic
//

import SwiftUI

struct OptionsSheet: View {
    let set: IntervalSet
    @Binding var isPresented: Bool
    let onEdit: () -> Void
    let onDuplicate: (IntervalSet) -> Void
    let onDelete: () -> Void
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .foregroundStyle(.primary)
                }
                Button {
                    let duplicated = IntervalSet(
                        name: set.name + " Copy",
                        intervals: set.intervals.map { i in
                            Interval(name: i.name, durationSeconds: i.durationSeconds, cueType: i.cueType)
                        },
                        cycleMode: set.cycleMode
                    )
                    onDuplicate(duplicated)
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                        .foregroundStyle(.primary)
                }
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                Button {
                    onClose()
                } label: {
                    Label("Close", systemImage: "xmark.circle")
                        .foregroundStyle(.primary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.visible)
            .navigationTitle("Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onClose()
                    }
                }
            }
        }
    }
}
