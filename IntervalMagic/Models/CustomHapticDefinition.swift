//
//  CustomHapticDefinition.swift
//  IntervalMagic
//

import Foundation

struct CustomHapticDefinition: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String?
    /// Time offsets in seconds from start for each tap.
    var pattern: [Double]
}
