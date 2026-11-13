//
//  FirebaseService.swift
//  excero
//
//  Created by Alessandro Silacci on 13.09.22.
//

import Foundation
import FirebaseCore

class FirebaseService: NSObject {
    static let instance = FirebaseService()
    
    func configure() {
            FirebaseApp.configure()
    }
}
