//
//  ModelController.swift
//  excero
//
//  Created by Alessandro Silacci on 22.08.22.
//

import Foundation
import CoreData

class ModelController<T> where T: NSManagedObject  {
    private var mainContext: NSManagedObjectContext = CoreDataController.instance.mainContext
    private let privateContext: NSManagedObjectContext
    
    internal init() {
        self.privateContext = CoreDataController.instance.mainContext
    }
    
    
    func list() -> [T] {
        let fetchRequest: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        do {
            let results = try self.privateContext.fetch(fetchRequest)
            return results
        }
        catch {
            print("hello")
        }
        return []
    }
    
    func get(id: NSManagedObjectID) -> T? {
        let fetchRequest: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        fetchRequest.predicate = NSPredicate(format: "ObjectID == %@", id)
        do {
            let result = try self.privateContext.fetch(fetchRequest)
            return result[0]
        }
        catch {
            print("hello")
        }
        return nil
    }
    
    func get(formatString: String, valueString: String? = nil, valueInt: Int? = nil) -> T? {
        let fetchRequest: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        if let valueString = valueString {
            fetchRequest.predicate = NSPredicate(format: formatString, valueString)
        }
        
        if let valueInt = valueInt {
            fetchRequest.predicate = NSPredicate(format: formatString, valueInt)
        }
        do {
            return try self.privateContext.performAndWait {
                let result = try self.privateContext.fetch(fetchRequest)
                if result.count > 0 {
                    return result[0]
                }
                return nil
            }
        }
        catch {
            print("hello")
        }
        return nil
    }
    
    func executePredicate(_ request: NSPredicate) -> [T]? {
        let fetchRequest: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        fetchRequest.predicate = request
        do {
            return try self.privateContext.performAndWait {
                return try self.privateContext.fetch(fetchRequest)
            }
        } catch {
            ResourcesManager.logger.error("ModelController.executePredicate encountering an error on fetch. Detailed error: \(error)")
        }
        return nil
    }
    
    func executePredicate(_ request: NSPredicate, expression: NSExpression, fetchProps: [String], groupByProperties: [String]) -> NSArray? {
        let fetchRequest: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        fetchRequest.predicate = request
        fetchRequest.resultType = .dictionaryResultType
        let expDesc = NSExpressionDescription()
        expDesc.expressionResultType = .objectIDAttributeType
        expDesc.expression = expression
        expDesc.name = "expDesc"
        fetchRequest.propertiesToFetch = ["end", expDesc]
        fetchRequest.propertiesToGroupBy = groupByProperties
        
        do {
            let result = try self.privateContext.fetch(fetchRequest) as NSArray
            return result
        } catch {
            print("hello")
        }
        return nil
    }
    
    func getLast() -> T? {
        let fetchRequest: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "objectID", ascending: false)]
        do {
            return try self.privateContext.performAndWait {
                let result = try self.privateContext.fetch(fetchRequest)
                if result.count > 0 {
                    return result[0]
                }
                return nil
            }
        }
        catch {
            print("hello")
        }
        return nil
    }
}
