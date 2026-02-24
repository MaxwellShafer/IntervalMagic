//
//  IntervalSetStore.swift
//  IntervalMagic
//

import Foundation
import SwiftData

@Observable
final class IntervalSetStore {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [IntervalSet] {
        let descriptor = FetchDescriptor<IntervalSetEntity>(sortBy: [SortDescriptor(\.name)])
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toIntervalSet() }
    }

    func save(_ set: IntervalSet) throws {
        if let existing = try fetchEntity(by: set.id) {
            updateEntity(existing, with: set)
        } else {
            _ = IntervalSetEntity.from(set, modelContext: modelContext)
        }
        try modelContext.save()
    }

    func delete(_ set: IntervalSet) throws {
        if let entity = try fetchEntity(by: set.id) {
            modelContext.delete(entity)
            try modelContext.save()
        }
    }

    func delete(id: UUID) throws {
        if let entity = try fetchEntity(by: id) {
            modelContext.delete(entity)
            try modelContext.save()
        }
    }

    private func fetchEntity(by id: UUID) throws -> IntervalSetEntity? {
        var descriptor = FetchDescriptor<IntervalSetEntity>(
            predicate: #Predicate<IntervalSetEntity> { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func updateEntity(_ entity: IntervalSetEntity, with set: IntervalSet) {
        entity.name = set.name
        entity.cycleMode = set.cycleMode
        for interval in entity.intervals {
            modelContext.delete(interval)
        }
        entity.intervals = []
        let newIntervals = set.intervals.map { interval in
            let e = IntervalEntity.from(interval)
            modelContext.insert(e)
            e.intervalSet = entity
            return e
        }
        entity.intervals = newIntervals
    }
}
