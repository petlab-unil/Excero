//
//  Representation.swift
//  excero
//
//  Created by Alessandro on 19.02.24.
//

import Foundation
import SpriteKit
import CoreData


protocol Representation {
    
}

protocol SpriteKitRepresentable {
    associatedtype SpriteKitElement
    associatedtype RepresentationElement: Representation
    static func fromSK(element: SpriteKitElement) -> RepresentationElement?
    func toSK() -> SpriteKitElement?
}

protocol CoreDataRepresentable {
    associatedtype CoreDataElement: NSManagedObject
    associatedtype RepresentationElement: Representation
    
    static func fromCD(element: CoreDataElement) -> RepresentationElement?
    func toCD() -> CoreDataElement?
}

extension CoreDataRepresentable {
    func checkCoreData(_ condition: @escaping (_ element: CoreDataElement) -> Bool) -> CoreDataElement? {
        let localCollection = ModelController<CoreDataElement>().list()
        
        for element in localCollection {
            if condition(element) {
                return element
            }
        }
        return nil
    }
}

protocol CodableRepresentable {
    associatedtype CodableElement
    associatedtype RepresentationElement: Representation
    
    static func fromCodable(element: CodableElement) -> RepresentationElement?
    func toCodable() -> CodableElement?
    static func fromURL(url: String) async throws -> RepresentationElement?
}

protocol AsyncSpriteKitRepresentable {
    associatedtype SpriteKitElement
    associatedtype RepresentationElement: Representation
    static func fromSK(element: SpriteKitElement) async throws -> RepresentationElement?
    func toSK() -> SpriteKitElement?
}

protocol AsyncCoreDataRepresentable {
    associatedtype CoreDataElement: NSManagedObject
    associatedtype RepresentationElement: Representation
    
    static func fromCD(element: CoreDataElement) async throws -> RepresentationElement?
    func toCD() -> CoreDataElement?
}

extension AsyncCoreDataRepresentable {
    func checkCoreData(_ condition: @escaping (_ element: CoreDataElement) -> Bool) -> CoreDataElement? {
        let localCollection = ModelController<CoreDataElement>().list()
        
        for element in localCollection {
            if condition(element) {
                return element
            }
        }
        return nil
    }
}

protocol AsyncCodableRepresentable {
    associatedtype CodableElement
    associatedtype RepresentationElement: Representation
    
    static func fromCodable(element: CodableElement) async throws -> RepresentationElement?
    func toCodable() -> CodableElement?
    static func fromURL(url: String) async throws -> RepresentationElement?
}
