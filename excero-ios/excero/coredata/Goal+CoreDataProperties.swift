//
//  Goal+CoreDataProperties.swift
//  excero
//
//  Created by Alessandro on 14.11.23.
//
//

import Foundation
import CoreData


extension Goal {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Goal> {
        return NSFetchRequest<Goal>(entityName: "Goal")
    }

    @NSManaged public var url: String?
    @NSManaged public var id: Int32
    @NSManaged public var value: Int32
    @NSManaged public var start: Date?
    @NSManaged public var end: Date?
    @NSManaged public var attained: Bool
    @NSManaged public var week: InterventionWeek?

}

extension Goal : Identifiable {

}
