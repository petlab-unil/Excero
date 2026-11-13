//
//  ExperimentalCondition+CoreDataProperties.swift
//  excero
//
//  Created by Alessandro on 03.10.23.
//
//

import Foundation
import CoreData


extension ExperimentalCondition {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExperimentalCondition> {
        return NSFetchRequest<ExperimentalCondition>(entityName: "ExperimentalCondition")
    }

    @NSManaged public var url: String?
    @NSManaged public var acronym: String?
    @NSManaged public var name: String?
    @NSManaged public var start: Date?
    @NSManaged public var end: Date?

}

extension ExperimentalCondition : Identifiable {

}
