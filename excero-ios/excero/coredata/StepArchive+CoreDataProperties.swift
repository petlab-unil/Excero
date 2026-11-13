//
//  StepArchive+CoreDataProperties.swift
//  excero
//
//  Created by Alessandro Silacci on 30.08.22.
//
//

import Foundation
import CoreData


extension StepArchive {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StepArchive> {
        return NSFetchRequest<StepArchive>(entityName: "StepArchive")
    }

    @NSManaged public var value: Int32
    @NSManaged public var start: Date?
    @NSManaged public var end: Date?
    @NSManaged public var week: InterventionWeek?

}

extension StepArchive : Identifiable {

}
