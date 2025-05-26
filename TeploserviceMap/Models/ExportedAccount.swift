//
//  File.swift
//  TeploserviceMap
//
//  Created by Shamil Aglarov on 26.05.2025.
//

import Foundation

struct ExportedAccount: Codable {
    let accountNumber: String
    let fio: String
    let area: Double
    let status: String
    let openDate: Date?
    let closeDate: Date?
    let phone: String
    let email: String
    let address: String
}
