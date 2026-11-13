//
//  AvatarTypeRepresentation.swift
//  excero
//
//  Created by Alessandro on 09.05.24.
//

import Foundation

class AvatarTypeRepresentation: Representation {
    
    private var _url: String?
    private var _name: String?
    private var _avatarPieces: [AvatarPieceRepresentation]?

    private static let coreModelController: ModelController<AvatarType> = ModelController<AvatarType>()
    
    public var url: String? {
        get {
            return self._url
        }
    }
    
    public var name: String? {
        get {
            return self._name
        }
    }
    
    public var avatarPieces: [AvatarPieceRepresentation]? {
        get {
            return self._avatarPieces
        }
        set {
            self._avatarPieces = newValue
        }
    }
    
    
    init(url: String, name: String) {
        self._url = url
        self._name = name
    }
}

extension AvatarTypeRepresentation: AsyncCodableRepresentable {
    typealias CodableElement = AvatarTypeCodable
    typealias RepresentationElement = AvatarTypeRepresentation
    
    static func fromCodable(element: AvatarTypeCodable) async throws -> AvatarTypeRepresentation? {
        let representation = AvatarTypeRepresentation(url: element.url, name: element.typeName)
        
        /*var avatarPieces: [AvatarPieceRepresentation]? = nil
        if let pieces = element.avatarPiecesUrls {
            avatarPieces = []
            for piece in pieces {
                if let pieceRep = try await AvatarPieceRepresentation.fromURL(url: piece) {
                    avatarPieces?.append(pieceRep)
                }
            }
            representation.avatarPieces = avatarPieces
        }*/
        return representation
    }
    
    func toCodable() -> AvatarTypeCodable? {
        guard let name = self._name else {return nil}
        return AvatarTypeCodable(url: self._url ?? "", typeName: name, avatarPiecesUrls: nil)
    }
    
    static func fromURL(url: String) async throws -> AvatarTypeRepresentation? {
        abort()
    }
}

extension AvatarTypeRepresentation: AsyncCoreDataRepresentable {
    typealias CoreDataElement = AvatarType
    
    static func fromCD(element: AvatarType) async throws -> AvatarTypeRepresentation? {
        guard let name = element.name else {return nil}
        let url = element.url ?? ""
        
        let representation = AvatarTypeRepresentation(url: url, name: name)
        
        var avatarPieces: [AvatarPieceRepresentation]? = nil
        if let pieces = element.pieces {
            avatarPieces = []
            for piece in pieces {
                if let pieceRep = try await AvatarPieceRepresentation.fromCDAvatarPiece(piece: piece as! AvatarPiece) {
                    avatarPieces?.append(pieceRep)
                }
            }
            representation.avatarPieces = avatarPieces
        }
        
        return representation
    }
    
    func toCD() -> AvatarType? {
        var predicate: NSPredicate?
        if let url = self._url {
            predicate = NSPredicate(format: "url == %@", url)
        } else if let name = self._name {
            predicate = NSPredicate(format: "name == %@", name)
        }
        
        var element: AvatarType?
        if let predicate, let cdElements = AvatarTypeRepresentation.coreModelController.executePredicate(predicate),
        let last = cdElements.last {
            element = last
        }
        if element == nil {
            element = AvatarType(context: CoreDataController.instance.mainContext)
        }
        if let element {
            element.url = self._url
            element.name = self._name
            
            if let pieces = self._avatarPieces {
                var avatarPieces: [AvatarPiece] = []
                for piece in pieces {
                    if let nsPiece = piece.toCDAvatarPiece() {
                        avatarPieces.append(nsPiece)
                    }
                }
                element.pieces = NSSet(array: avatarPieces)
            }
            
            return element
        }
        return nil
    }
}
