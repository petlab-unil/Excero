//
//  Message+CoreDataProperties.swift
//  
//
//  Created by Alessandro on 19.02.24.
//
//

import Foundation
import CoreData


extension Message {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Message> {
        return NSFetchRequest<Message>(entityName: "Message")
    }

    @NSManaged public var url: String?
    @NSManaged public var content: String?
    @NSManaged public var authorUser: User?
    @NSManaged public var authorSimulatedPeer: SimulatedPeer?
    @NSManaged public var conversation: Conversation?

}
