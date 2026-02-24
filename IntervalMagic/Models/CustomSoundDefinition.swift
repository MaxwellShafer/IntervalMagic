//
//  CustomSoundDefinition.swift
//  IntervalMagic
//

import Foundation

struct CustomSoundDefinition: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String?
    var fileName: String
    var waitUntilFinished: Bool
}
