//
//  newIerarh.swift
//  TeploserviceMap
//
//  Created by Shamil Aglarov on 26.05.2025.
//

import Foundation

struct ExportedSavedLocation: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
    let floors: Int?
    let yearBuilt: Int?
    let rooms: Int?
    let accounts: [ExportedAccount]
    let totalArea: Double?
    let managementCompany: String?
}
