//
//  Avatar+CoreDataProperties.swift
//  excero
//
//  Created by Alessandro Silacci on 22.08.22.
//
//

import Foundation
import CoreData


extension Avatar {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Avatar> {
        return NSFetchRequest<Avatar>(entityName: "Avatar")
    }
    
    @NSManaged public var url: String
    @NSManaged public var isSelf: Bool
    @NSManaged public var tint: String
    @NSManaged public var image: String
    @NSManaged public var user: User?
    @NSManaged public var simulatedPeerModel: SimulatedPeerModel?
    @NSManaged public var base: AvatarPiece?
    @NSManaged public var head: AvatarPiece?
    @NSManaged public var hairs: AvatarPiece?
    @NSManaged public var shirt: AvatarPiece?
    @NSManaged public var trousers: AvatarPiece?
    @NSManaged public var shoes: AvatarPiece?

}

extension Avatar : Identifiable {

}
