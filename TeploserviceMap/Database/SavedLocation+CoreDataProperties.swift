//
//  SavedLocation+CoreDataProperties.swift
//  TeploserviceMap
//
//  Created by Murad Tataev on 25.05.2025.
//
//

import Foundation
import CoreData


extension SavedLocation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SavedLocation> {
        return NSFetchRequest<SavedLocation>(entityName: "SavedLocation")
    }

    @NSManaged public var accounts: Int32
    @NSManaged public var floors: Int32
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var managementCompany: String?
    @NSManaged public var name: String?
    @NSManaged public var rooms: Int32
    @NSManaged public var totalArea: Double
    @NSManaged public var yearBuilt: Int32
    @NSManaged public var boilerHouse: BoilerHouse?
    @NSManaged public var myAccounts: NSSet?

}

// MARK: Generated accessors for myAccounts
extension SavedLocation {

    @objc(addMyAccountsObject:)
    @NSManaged public func addToMyAccounts(_ value: MyAccount)

    @objc(removeMyAccountsObject:)
    @NSManaged public func removeFromMyAccounts(_ value: MyAccount)

    @objc(addMyAccounts:)
    @NSManaged public func addToMyAccounts(_ values: NSSet)

    @objc(removeMyAccounts:)
    @NSManaged public func removeFromMyAccounts(_ values: NSSet)

}

extension SavedLocation : Identifiable {

}
