//
//  AvatarType+CoreDataProperties.swift
//  excero
//
//  Created by Alessandro on 09.05.24.
//
//

import Foundation
import CoreData


extension AvatarType {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AvatarType> {
        return NSFetchRequest<AvatarType>(entityName: "AvatarType")
    }

    @NSManaged public var name: String?
    @NSManaged public var url: String?
    @NSManaged public var pieces: NSSet?

}

// MARK: Generated accessors for pieces
extension AvatarType {

    @objc(addPiecesObject:)
    @NSManaged public func addToPieces(_ value: AvatarPiece)

    @objc(removePiecesObject:)
    @NSManaged public func removeFromPieces(_ value: AvatarPiece)

    @objc(addPieces:)
    @NSManaged public func addToPieces(_ values: NSSet)

    @objc(removePieces:)
    @NSManaged public func removeFromPieces(_ values: NSSet)

}

extension AvatarType : Identifiable {

}
