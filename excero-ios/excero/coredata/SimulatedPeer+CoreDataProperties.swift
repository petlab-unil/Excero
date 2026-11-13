//
//  SimulatedPeer+CoreDataProperties.swift
//  excero
//
//  Created by Alessandro on 03.10.23.
//
//

import Foundation
import CoreData


extension SimulatedPeer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SimulatedPeer> {
        return NSFetchRequest<SimulatedPeer>(entityName: "SimulatedPeer")
    }

    @NSManaged public var url: String?
    @NSManaged public var name: String?
    @NSManaged public var model: SimulatedPeerModel?

}

extension SimulatedPeer : Identifiable {

}
