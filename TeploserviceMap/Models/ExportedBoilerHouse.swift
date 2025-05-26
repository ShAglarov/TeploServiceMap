//
//  File.swift
//  TeploserviceMap
//
//  Created by Shamil Aglarov on 26.05.2025.
//

import Foundation

struct ExportedBoilerHouse: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
    let savedLocations: [ExportedSavedLocation]
}
