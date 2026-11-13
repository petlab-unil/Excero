//
//  InterventionWeek+CoreDataProperties.swift
//  excero
//
//  Created by Alessandro on 06.11.23.
//
//

import Foundation
import CoreData


extension InterventionWeek {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<InterventionWeek> {
        return NSFetchRequest<InterventionWeek>(entityName: "InterventionWeek")
    }

    @NSManaged public var url: String?
    @NSManaged public var begin: Date?
    @NSManaged public var end: Date?

}

extension InterventionWeek : Identifiable {

}
