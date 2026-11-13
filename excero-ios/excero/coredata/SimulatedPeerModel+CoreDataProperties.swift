//
//  SimulatedPeerModel+CoreDataProperties.swift
//  excero
//
//  Created by Alessandro on 06.02.24.
//
//

import Foundation
import CoreData


extension SimulatedPeerModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SimulatedPeerModel> {
        return NSFetchRequest<SimulatedPeerModel>(entityName: "SimulatedPeerModel")
    }

    @NSManaged public var url: String?
    @NSManaged public var preview: String?
    @NSManaged public var avatar: Avatar?

}

extension SimulatedPeerModel : Identifiable {

}
