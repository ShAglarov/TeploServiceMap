//
//  SavedPoint.swift
//  TeploserviceMap
//
//  Created by Murad Tataev on 23.05.2025.
//

import Foundation
import CoreData
import CoreLocation

@objc(SavedLocation)
public class SavedLocation: NSManagedObject {}

extension SavedLocation {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SavedLocation> {
        return NSFetchRequest<SavedLocation>(entityName: "SavedLocation")
    }

    @NSManaged public var name: String
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var yearBuilt: Int32
    @NSManaged public var totalArea: Double
    @NSManaged public var floors: Int32
    @NSManaged public var rooms: Int32
    @NSManaged public var accounts: Int32
    @NSManaged public var managementCompany: String?

    // --- Добавь это свойство для связи с котельной ---
    @NSManaged public var boilerHouse: BoilerHouse?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension SavedLocation: Identifiable {}

