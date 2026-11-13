//
//  AvatarPiece+CoreDataProperties.swift
//  excero
//
//  Created by Alessandro Silacci on 22.08.22.
//
//

import Foundation
import CoreData


extension AvatarPiece {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AvatarPiece> {
        return NSFetchRequest<AvatarPiece>(entityName: "AvatarPiece")
    }

    @NSManaged public var imageName: String?
    @NSManaged public var sizeWidth: Double
    @NSManaged public var sizeHeight: Double
    @NSManaged public var posX: Double
    @NSManaged public var posY: Double
    @NSManaged public var posZ: Double
    @NSManaged public var file: String
    @NSManaged public var url: String
    @NSManaged public var type: String

}

extension AvatarPiece : Identifiable {

}
