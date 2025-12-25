//
//  ExportedPoint.swift
//  TeploserviceMap
//
//  Created by Shamil Aglarov on 24.05.2025.
//

import Foundation

struct ExportedPoint: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
    let yearBuilt: Int?
    let totalArea: Double?
    let floors: Int?
    let rooms: Int?
    let accounts: Int?
    let managementCompany: String?
}
