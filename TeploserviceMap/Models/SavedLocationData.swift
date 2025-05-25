//
//  SavedLocationData.swift
//  TeploserviceMap
//
//  Created by Shamil Aglarov on 24.05.2025.
//

import Foundation

struct SavedLocationData: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
    let floors: Int?
    let yearBuilt: Int?
    let rooms: Int?
    let accounts: Int?
    let totalArea: Double?
    let managementCompany: String?
}
