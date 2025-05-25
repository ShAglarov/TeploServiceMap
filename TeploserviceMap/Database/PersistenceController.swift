//
//  PersistenceController.swift
//  TeploserviceMap
//
//  Created by Shamil Aglarov on 23.05.2025.
//

import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "TeploserviceMap") // Имя .xcdatamodeld без расширения!
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
