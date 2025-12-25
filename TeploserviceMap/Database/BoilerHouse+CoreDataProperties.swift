//
//  BoilerHouse+CoreDataProperties.swift
//  TeploserviceMap
//
//  Created by Murad Tataev on 25.05.2025.
//
//

import Foundation
import CoreData

public class BoilerHouse: NSManagedObject {

}

extension BoilerHouse {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BoilerHouse> {
        return NSFetchRequest<BoilerHouse>(entityName: "BoilerHouse")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?
    @NSManaged public var savedLocations: NSSet?

}

// MARK: Generated accessors for savedLocations
extension BoilerHouse {

    @objc(addSavedLocationsObject:)
    @NSManaged public func addToSavedLocations(_ value: SavedLocation)

    @objc(removeSavedLocationsObject:)
    @NSManaged public func removeFromSavedLocations(_ value: SavedLocation)

    @objc(addSavedLocations:)
    @NSManaged public func addToSavedLocations(_ values: NSSet)

    @objc(removeSavedLocations:)
    @NSManaged public func removeFromSavedLocations(_ values: NSSet)

}

extension BoilerHouse : Identifiable {

}
