//
//  SavedLocation+CoreDataClass.swift
//  TeploserviceMap
//
//  Created by Shamil Aglarov on 24.05.2025.
//
//


import CoreLocation
import CoreData

public class SavedLocation: NSManagedObject {

}

extension SavedLocation {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
