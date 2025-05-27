//
//  MyAccount+CoreDataProperties.swift
//  TeploserviceMap
//
//  Created by Murad Tataev on 25.05.2025.
//
//

import Foundation
import CoreData

public class MyAccount: NSManagedObject {

}

extension MyAccount {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MyAccount> {
        return NSFetchRequest<MyAccount>(entityName: "MyAccount")
    }

    @NSManaged public var accountNumber: String?
    @NSManaged public var fio: String?
    @NSManaged public var area: Double
    @NSManaged public var status: String?
    @NSManaged public var openDate: Date?
    @NSManaged public var closeDate: Date?
    @NSManaged public var address: String?
    @NSManaged public var phone: String?
    @NSManaged public var email: String?
    @NSManaged public var serviceType: String?
    @NSManaged public var location: SavedLocation?

}

extension MyAccount : Identifiable {

}
