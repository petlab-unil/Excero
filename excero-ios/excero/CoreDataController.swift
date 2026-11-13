//
//  CoreDataController.swift
//  excero
//
//  Created by Alessandro Silacci on 22.08.22.
//

import Foundation
import CoreData

class CoreDataController {
    static let instance = CoreDataController()
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Excero")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Persistent storage could not be loaded \(error)")
            }
        }
        return container
    }()
    
    var mainContext: NSManagedObjectContext {
        return self.persistentContainer.viewContext
    }
    
    private init() {}
    
    func backgroundContext() -> NSManagedObjectContext {
        return self.persistentContainer.newBackgroundContext()
    }
}
