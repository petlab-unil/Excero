//
//  SKAvatarAdapter.swift
//  excero
//
//  Created by Alessandro Silacci on 24.08.22.
//

import Foundation
import CoreData
import SpriteKit

enum SKAvatarAdapterError: Error {
    case avatarPieceCouldNotBeConvertedError(piece: AvatarPiece, error: String)
}

@available(*, deprecated)
class SKAvatarAdapter {

    internal init() {}
    
    static func convert(avatar: Avatar, scene: SKScene) throws -> SKAvatar? {
        var avatarHead: SKAvatarPiece? = nil
        var avatarHairs: SKAvatarPiece? = nil
        var avatarShirt: SKAvatarPiece? = nil
        var avatarTrousers: SKAvatarPiece? = nil
        var avatarShoes: SKAvatarPiece? = nil
        let avatarBase = try SKAvatarPieceAdapter.convert(piece: avatar.base!)
        avatarBase.color = ColorUtility.colorWithHexString(hexString: avatar.tint)
        avatarBase.colorBlendFactor = 0.7
        if let head = avatar.head {
            do {
                avatarHead = try SKAvatarPieceAdapter.convert(piece: head)
            } catch {
                throw SKAvatarAdapterError.avatarPieceCouldNotBeConvertedError(piece: head, error: error.localizedDescription)
            }
        }
        if let hairs = avatar.hairs {
            do {
                avatarHairs = try SKAvatarPieceAdapter.convert(piece: hairs)
            } catch {
                throw SKAvatarAdapterError.avatarPieceCouldNotBeConvertedError(piece: hairs, error: error.localizedDescription)
            }
        }
        if let shirt = avatar.shirt {
            do {
                avatarShirt = try SKAvatarPieceAdapter.convert(piece: shirt)
            } catch {
                throw SKAvatarAdapterError.avatarPieceCouldNotBeConvertedError(piece: shirt, error: error.localizedDescription)
            }
        }
        if let trousers = avatar.trousers {
            do {
                avatarTrousers = try SKAvatarPieceAdapter.convert(piece: trousers)
            } catch {
                throw SKAvatarAdapterError.avatarPieceCouldNotBeConvertedError(piece: trousers, error: error.localizedDescription)
            }
        }
        if let shoes = avatar.shoes {
            do {
                avatarShoes = try SKAvatarPieceAdapter.convert(piece: shoes)
            } catch {
                throw SKAvatarAdapterError.avatarPieceCouldNotBeConvertedError(piece: shoes, error: error.localizedDescription)
            }
        }
        return SKAvatar(base: avatarBase,
                        head: avatarHead,
                        hairs: avatarHairs,
                        shirt: avatarShirt,
                        trousers: avatarTrousers,
                        shoes: avatarShoes,
                        parentScene: scene)
        
    }
    
    static func convert(avatar: SKAvatar, avatarType: AvatarType, isSelf: Bool) -> AvatarCodable? {
        var hairsURL = ""
        var shirtURL = ""
        var trousersURL = ""
        var shoesURL = ""
        var baseURL = ""
        
        
        if let hairs = avatar.getHairs()?.resURL {
            hairsURL = hairs
        }
        //guard let head = avatar.getHead()?.resURL else { return nil }
        if let shirt = avatar.getShirt()?.resURL {
            shirtURL = shirt
        }
        if let trousers = avatar.getTrousers()?.resURL {
            trousersURL = trousers
        }
        if let shoes = avatar.getShoes()?.resURL {
            shoesURL = shoes
        }
        if let base = avatar.getBase()?.resURL {
            baseURL = base
        }
        var tint: String = "FFFFFF"
        if let base = avatar.getBase() {
            if let color = ColorUtility.toHex(color: base.color) {
                tint = color
            }
        }
        
        return AvatarCodable(url: "",
                             tint: tint,
                             base: baseURL,
                             head: hairsURL,
                             torso: shirtURL,
                             legs: trousersURL,
                             shoes: shoesURL,
                             type: avatarType.url ?? "")
    }
    
    static func convert(avatar: SKAvatar, isSelf: Bool) -> Avatar {
        let avatarModel = Avatar(context: CoreDataController.instance.mainContext)
        avatarModel.isSelf = isSelf
        if let base = avatar.getBase() {
            avatarModel.base = SKAvatarPieceAdapter.convert(piece: base)
            if let color = ColorUtility.toHex(color: base.color) {
                avatarModel.tint = color
            } else {
                avatarModel.tint = "FFFFFF"
            }
        }
        
        if let hairs = avatar.getHairs() {
            avatarModel.hairs = SKAvatarPieceAdapter.convert(piece: hairs)
        }
        
        if let head = avatar.getHead() {
            avatarModel.head = SKAvatarPieceAdapter.convert(piece: head)
        }
        
        if let shirt = avatar.getShirt() {
            avatarModel.shirt = SKAvatarPieceAdapter.convert(piece: shirt)
        }
        
        if let trousers = avatar.getTrousers() {
            avatarModel.trousers = SKAvatarPieceAdapter.convert(piece: trousers)
        }
        
        if let shoes = avatar.getShoes() {
            avatarModel.shoes = SKAvatarPieceAdapter.convert(piece: shoes)
        }
        
        return avatarModel
    }
    
    static func toImage(avatar: SKSpriteNode) -> UIImage? {
        guard let textureCGImage = avatar.texture?.cgImage() else {return nil}
        let image = UIImage(cgImage: textureCGImage)
        let data = image.pngData()
        return UIImage(data: data!)
    }
}
