//
//  ExportedPoint.swift
//  TeploserviceMap
//
//  Created by Murad Tataev on 23.05.2025.
//

import Foundation
import CoreLocation

struct ExportedPoint: Codable {
    let name: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
