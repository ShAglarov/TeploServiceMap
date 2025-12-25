//
//  PersistenceController.swift
//  TeploserviceMap
//
//  Created by Shamil Aglarov on 23.05.2025.
//

import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    var boilers: [BoilerHouse] = []
    var savesLocations: [SavedLocation] = []
    var accounts: [MyAccount] = []
    
    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "TeploserviceMap") // Имя вашей .xcdatamodeld
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Ошибка загрузки хранилища Core Data: \(error)")
            }
        }
    }

    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    
    
}
