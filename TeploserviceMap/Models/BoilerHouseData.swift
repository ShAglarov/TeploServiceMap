//
//  BoilerHouseData.swift
//  TeploserviceMap
//
//  Created by Shamil Aglarov on 24.05.2025.
//

import Foundation

struct BoilerHouseData: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
    let savedLocations: [SavedLocationData]
}
