//
//  BoilerHouse.swift
//  TeploserviceMap
//
//  Created by Murad Tataev on 23.05.2025.
//

import Foundation
import CoreData
import CoreLocation

@objc(BoilerHouse)
public class BoilerHouse: NSManagedObject {}

extension BoilerHouse {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<BoilerHouse> {
        return NSFetchRequest<BoilerHouse>(entityName: "BoilerHouse")
    }

    @NSManaged public var name: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var yearBuilt: Int32        // если нужен
    @NSManaged public var capacity: Double        // если нужна мощность
    @NSManaged public var address: String?        // если нужен адрес

    // --- Добавь это свойство для связи с SavedLocation ---
    @NSManaged public var locations: NSSet?       // Множество связанных SavedLocation

    // Быстрое получение координаты
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension BoilerHouse: Identifiable {}

// MARK: - Generated accessors for locations (если связь один-ко-многим)
extension BoilerHouse {
    @objc(addLocationsObject:)
    @NSManaged public func addToLocations(_ value: SavedLocation)

    @objc(removeLocationsObject:)
    @NSManaged public func removeFromLocations(_ value: SavedLocation)

    @objc(addLocations:)
    @NSManaged public func addToLocations(_ values: NSSet)

    @objc(removeLocations:)
    @NSManaged public func removeFromLocations(_ values: NSSet)
}
