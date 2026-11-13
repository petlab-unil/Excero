//
//  AvatarRepresentation.swift
//  excero
//
//  Created by Alessandro on 02.10.23.
//

import Foundation
import SpriteKit
import CoreData
class AvatarRepresentation {
    private var _url: String?
    private var _tint: String?
    private var _base: AvatarPieceRepresentation?
    private var _hairs: AvatarPieceRepresentation?
    private var _head: AvatarPieceRepresentation?
    private var _torso: AvatarPieceRepresentation?
    private var _legs: AvatarPieceRepresentation?
    private var _shoes: AvatarPieceRepresentation?
    private var _type: String?
    private var _image: String?
    
    private static let coreModelController: ModelController<Avatar> = ModelController<Avatar>()
    
    var type: String? {
        set {
            self._type = newValue
        }
        get {
            return self._type
        }
    }
    
    var url: String? {
        get {
            return self._url
        }
    }
    
    var tint: String? {
        get {
            return self._tint
        }
        set {
            self._tint = newValue
        }
    }
    
    var base: AvatarPieceRepresentation? {
        get {
            return self._base
        }
        set {
            self._base = newValue
        }
    }
    
    var hairs: AvatarPieceRepresentation? {
        get {
            return self._hairs
        }
        set {
            self._hairs = newValue
        }
    }
    
    var head: AvatarPieceRepresentation? {
        get {
            return self._head
        }
        set {
            self._head = newValue
        }
    }
    
    var top: AvatarPieceRepresentation? {
        get {
            return self._torso
        }
        set {
            self._torso = newValue
        }
    }
    
    var legs: AvatarPieceRepresentation? {
        get {
            return self._legs
        }
        set {
            self._legs = newValue
        }
    }
    
    var shoes: AvatarPieceRepresentation? {
        get {
            return self._shoes
        }
        set {
            self._shoes = newValue
        }
    }
    
    var image: String? {
        get {
            return self._image
        }
        set {
            self._image = newValue
        }
    }
    
    internal init(url: String, tint: String, base: AvatarPieceRepresentation, hairs: AvatarPieceRepresentation?, head: AvatarPieceRepresentation?, torso: AvatarPieceRepresentation?, legs: AvatarPieceRepresentation?, shoes: AvatarPieceRepresentation?, type: String) {
        self._url = url
        self._tint = tint
        self._base = base
        self._head = head
        self._hairs = hairs
        self._torso = torso
        self._legs = legs
        self._shoes = shoes
        self._type = type
    }
    
    func generateAvatarImage(_ image: UIImage?, path: String) -> String? {
        guard let image = image else { return nil }
        if let  directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) as NSURL {
            do {
                let fullPath = directory.appendingPathComponent(path)!
                try image.pngData()!.write(to: fullPath)
                return path
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}

extension AvatarRepresentation {
    func toSKAvatar(parentScene: SKScene, forceLocal: Bool = false) async throws -> SKAvatar? {
        guard let base = try await self._base?.toSKAvatarPiece(parentScene: parentScene, forceLocal: forceLocal) else { return nil } // TODO: Throw Error
        let avatar = SKAvatar(base: base, head: try await self._head?.toSKAvatarPiece(parentScene: parentScene, forceLocal: forceLocal),
                        hairs: try await self._hairs?.toSKAvatarPiece(parentScene: parentScene, forceLocal: forceLocal),
                        shirt: try await self._torso?.toSKAvatarPiece(parentScene: parentScene, forceLocal: forceLocal),
                        trousers: try await self._legs?.toSKAvatarPiece(parentScene: parentScene, forceLocal: forceLocal),
                        shoes: try await self._shoes?.toSKAvatarPiece(parentScene: parentScene, forceLocal: forceLocal),
                        parentScene: parentScene)
        
        return avatar
    }
    
    static func fromSKAvatar(_ avatar: SKAvatar) -> AvatarRepresentation? {
        var baseRepresentation: AvatarPieceRepresentation
        var hairsRepresentation: AvatarPieceRepresentation?
        var headRepresentation: AvatarPieceRepresentation?
        var torsoRepresentation: AvatarPieceRepresentation?
        var legsRepresentation: AvatarPieceRepresentation?
        var shoesRepresentation: AvatarPieceRepresentation?
        
        if let aBase = avatar.getBase(), let base = AvatarPieceRepresentation.fromSKAvatarPiece(piece: aBase) {
            baseRepresentation = base
        } else {
            return nil
        } // TODO: throw Error
        if let hairs = avatar.getHairs() {
            hairsRepresentation = AvatarPieceRepresentation.fromSKAvatarPiece(piece: hairs)
        }
        if let head = avatar.getHead() {
            headRepresentation = AvatarPieceRepresentation.fromSKAvatarPiece(piece: head)
        }
        if let torso = avatar.getShirt() {
            torsoRepresentation = AvatarPieceRepresentation.fromSKAvatarPiece(piece: torso)
        }
        if let legs = avatar.getTrousers() {
            legsRepresentation = AvatarPieceRepresentation.fromSKAvatarPiece(piece: legs)
        }
        if let shoes = avatar.getShoes() {
            shoesRepresentation = AvatarPieceRepresentation.fromSKAvatarPiece(piece: shoes)
        }
        return AvatarRepresentation(url: "", tint: "",
                                    base: baseRepresentation,
                                    hairs: hairsRepresentation, head: headRepresentation,
                                    torso: torsoRepresentation, legs: legsRepresentation,
                                    shoes: shoesRepresentation, type: "")
    }
}

extension AvatarRepresentation {
    func checkCoreData<CoreDataElement: NSManagedObject>(formatString: String, valueString: String?) -> CoreDataElement? {
        guard let url else { return nil }
        return ModelController<CoreDataElement>().get(formatString: formatString, valueString: valueString)
    }
    func toCDAvatar(isSelf: Bool, user: UserRepresentation? = nil, sep: SimulatedPeerModelRepresentation? = nil, defaultTint: String = "FFFFF") -> Avatar? {
        var model: Avatar?
        
        if let avatarURL = self._url {
            model = AvatarRepresentation.coreModelController.get(formatString: "url = %@", valueString: avatarURL)
        }
        if model == nil {
            model = Avatar(context: CoreDataController.instance.mainContext)
        }
        
        model?.managedObjectContext?.perform {
            if let avatarURL = self._url {
                model?.url = avatarURL
            }
            model?.base = self._base?.toCDAvatarPiece()
            model?.hairs = self._hairs?.toCDAvatarPiece()
            if let head = model?.head {
                model?.head = self._head?.toCDAvatarPiece()
            }
            model?.shirt = self._torso?.toCDAvatarPiece()
            model?.trousers = self._legs?.toCDAvatarPiece()
            model?.shoes = self._shoes?.toCDAvatarPiece()
            if let tint = self._tint {
                model?.tint = tint
            } else {
                model?.tint = defaultTint
            }
            
            if let user {
                let userCD: User? = self.checkCoreData(formatString: "url = %@", valueString: user.url)
                model?.user = userCD
            }
            
            if let sep {
                let sepCD: SimulatedPeerModel? = self.checkCoreData(formatString: "url = %@", valueString: sep.url)
                model?.simulatedPeerModel = sepCD
            }
            model?.isSelf = isSelf
            do {
                try CoreDataController.instance.mainContext.save()
            } catch {
                ResourcesManager.logger.error("AvatarRepresentation.toCDAvatar could not save using coredata main context. Detailed error: \(error)")
            }
        }
        
        return model
    }
    
    static func fromCDAvatar(_ avatar: Avatar) async throws -> AvatarRepresentation? {
        var baseRepresentation: AvatarPieceRepresentation?
        var hairsRepresentation: AvatarPieceRepresentation?
        var headRepresentation: AvatarPieceRepresentation?
        var torsoRepresentation: AvatarPieceRepresentation?
        var legsRepresentation: AvatarPieceRepresentation?
        var shoesRepresentation: AvatarPieceRepresentation?
        var avatarRepresentation: AvatarRepresentation?
        let url = avatar.managedObjectContext?.performAndWait {
            return avatar.url
        }
        guard let url else { return nil }
        let tint = avatar.managedObjectContext?.performAndWait {
            return avatar.tint
        } ?? ""
        
        let base = avatar.managedObjectContext?.performAndWait {
            return avatar.base
        }
        if let base {
            baseRepresentation =  try await AvatarPieceRepresentation.fromCDAvatarPiece(piece: base)
        }
        guard let baseRepresentation else { return nil }
        let hairs = avatar.managedObjectContext?.performAndWait {
            return avatar.hairs
        }
        if let hairs {
            hairsRepresentation = try await AvatarPieceRepresentation.fromCDAvatarPiece(piece: hairs)
        }
        let head = avatar.managedObjectContext?.performAndWait {
            return avatar.head
        }
        if let head {
            headRepresentation = try await AvatarPieceRepresentation.fromCDAvatarPiece(piece: head)
        }
        let torso = avatar.managedObjectContext?.performAndWait {
            return avatar.shirt
        }
        if let torso {
            torsoRepresentation = try await AvatarPieceRepresentation.fromCDAvatarPiece(piece: torso)
        }
        let legs = avatar.managedObjectContext?.performAndWait {
            return avatar.trousers
        }
        if let legs {
            legsRepresentation = try await AvatarPieceRepresentation.fromCDAvatarPiece(piece: legs)
        }
        let shoes = avatar.managedObjectContext?.performAndWait {
            return avatar.shoes
        }
        if let shoes {
            shoesRepresentation = try await AvatarPieceRepresentation.fromCDAvatarPiece(piece: shoes)
        }
        
        avatarRepresentation = AvatarRepresentation(url: url, tint: tint,
                                                    base: baseRepresentation,
                                                    hairs: hairsRepresentation, head: headRepresentation,
                                                    torso: torsoRepresentation, legs: legsRepresentation,
                                                    shoes: shoesRepresentation, type: "")
        let image = avatar.managedObjectContext?.performAndWait {
            return avatar.image
        }
        avatarRepresentation?._image = image
        return avatarRepresentation
    }
}

extension AvatarRepresentation {
    func toCodable() -> AvatarCodable? {
        guard let url = self._url else { return nil } // TODO: throw Error
        guard let tint = self._tint else { return nil } // TODO: throw Error
        guard let base = self._base?.toCodable() else { return nil } // TODO: throw Error
        guard let head = self._hairs?.toCodable() else { return nil } // TODO: throw Error
        guard let torso = self._torso?.toCodable() else { return nil } // TODO: throw Error
        guard let legs = self._legs?.toCodable() else { return nil } // TODO: throw Error
        guard let shoes = self._shoes?.toCodable() else { return nil } // TODO: throw Error
        
        var typeUrl: String?
        
        let baseUrl: String = base.url
        let headUrl: String = head.url
        let torsoUrl: String = torso.url
        let legsUrl: String = legs.url
        let shoesUrl: String = shoes.url
        
        if let type = self._type {
            typeUrl = type
        }
        
        let codable = AvatarCodable(url: url, tint: tint,
                                    base: baseUrl, head: headUrl,
                                    torso: torsoUrl, legs: legsUrl,
                                    shoes: shoesUrl, type: typeUrl ?? "")
        return codable
    }
    
    static func fromURL(url: String) async throws -> AvatarRepresentation? {
        let decoder = JSONDecoder()
        let api = AuthenticatedApiFacade()
        let data = try await api.get(fullUrl: url, header: nil)
        if let data = data {
            let representation = await AvatarRepresentation.fromCodable(try decoder.decode(AvatarCodable.self, from: data))
            return representation
        }
        return nil
    }
    
    static func fromCodable(_ avatar: AvatarCodable) async -> AvatarRepresentation? {
        var avatarRepresentation: AvatarRepresentation?
        do {
            let baseRepresentation = try await AvatarPieceRepresentation.fromURL(url: avatar.base)
            let hairsRepresentation = try await AvatarPieceRepresentation.fromURL(url: avatar.head)
            let torsoRepresentation = try await AvatarPieceRepresentation.fromURL(url: avatar.torso)
            let legsRepresentation = try await AvatarPieceRepresentation.fromURL(url: avatar.legs)
            let shoesRepresentation = try await AvatarPieceRepresentation.fromURL(url: avatar.shoes)
            
            guard let base = baseRepresentation else { return nil }
            guard let hairs = hairsRepresentation else { return nil }
            guard let torso = torsoRepresentation else { return nil }
            guard let legs = legsRepresentation else { return nil }
            guard let shoes = shoesRepresentation else { return nil }
            
            avatarRepresentation = AvatarRepresentation(url: avatar.url, tint: avatar.tint,
                                        base: base, hairs: hairs,
                                        head: nil, torso: torso,
                                        legs: legs, shoes: shoes,
                                        type: avatar.type)
        } catch {
            print("Error while converting avatarpieces into representations: \(error.localizedDescription)")
        }
        return avatarRepresentation
    }
}
