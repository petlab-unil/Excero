//
//  User+CoreDataProperties.swift
//  excero
//
//  Created by Alessandro on 22.08.24.
//
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var url: String?
    @NSManaged public var username: String?
    @NSManaged public var avatar: Avatar?
    @NSManaged public var experimentalConditions: ExperimentalCondition?
    @NSManaged public var simulatedPeer: SimulatedPeer?
    @NSManaged public var stepRecords: NSSet?

}

// MARK: Generated accessors for stepRecords
extension User {

    @objc(addStepRecordsObject:)
    @NSManaged public func addToStepRecords(_ value: StepArchive)

    @objc(removeStepRecordsObject:)
    @NSManaged public func removeFromStepRecords(_ value: StepArchive)

    @objc(addStepRecords:)
    @NSManaged public func addToStepRecords(_ values: NSSet)

    @objc(removeStepRecords:)
    @NSManaged public func removeFromStepRecords(_ values: NSSet)

}

extension User : Identifiable {

}
