//
//  UserInformation+CoreDataProperties.swift
//  excero
//
//  Created by Alessandro Silacci on 20.04.23.
//
//

import Foundation
import CoreData


extension UserInformation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserInformation> {
        return NSFetchRequest<UserInformation>(entityName: "UserInformation")
    }

    @NSManaged public var email: String?
    @NSManaged public var password: String?
    @NSManaged public var refreshToken: String?
    @NSManaged public var token: String?

}

extension UserInformation : Identifiable {

}
