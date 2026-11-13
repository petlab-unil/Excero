//
//  Conversation+CoreDataProperties.swift
//  
//
//  Created by Alessandro on 19.02.24.
//
//

import Foundation
import CoreData


extension Conversation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Conversation> {
        return NSFetchRequest<Conversation>(entityName: "Conversation")
    }

    @NSManaged public var url: String?
    @NSManaged public var documentPath: String?
    @NSManaged public var user1: User?
    @NSManaged public var user2: User?
    @NSManaged public var simulatedPeer: SimulatedPeer?

}
