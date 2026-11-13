//
//  SKAvatarPieceAdapter.swift
//  excero
//
//  Created by Alessandro Silacci on 24.08.22.
//

import Foundation
import SpriteKit

@available(*, deprecated)
class SKAvatarPieceAdapter {
    
    static func convert(piece: AvatarPiece) throws -> SKAvatarPiece {
        return try SKAvatarPiece(imageName: piece.imageName!, size: CGSize(width: piece.sizeWidth, height: piece.sizeHeight),
                                 relativePosition: CGPoint(x: piece.posX, y: piece.posY), resURL: piece.url, resLocalURL: piece.file)
    }
    
    static func convert(piece: AvatarPieceCodable) async throws -> SKAvatarPiece?  {
        guard let resURL = URL(string: piece.file.replacingOccurrences(of: "http", with: "https")) else { return nil }
        if let data = try? Data(contentsOf: resURL) {
            if let img = UIImage(data: data) {
                guard let url = img.storeSprite(at: .documentDirectory, fileName: piece.name) else { return nil }
                
                let avatarPiece = try await SKAvatarPiece(imageName: piece.name, size: CGSize(width: piece.width, height: piece.height),
                                                      relativePosition: CGPoint(x: piece.positionX, y: piece.positionY), resURL: piece.url, resLocalURL: url.absoluteString)
                return avatarPiece
            }
        }
        return nil
    }
    
    static func convert(piece: SKAvatarPiece) -> AvatarPieceCodable {
        let imageName = piece.getImageName()
        let posX = piece.getRelativePosition().x
        let posY = piece.getRelativePosition().y
        let sizeWidth = piece.getPieceSize().width
        let sizeHeight = piece.getPieceSize().height
        var url = ""
        if let apURL = piece.resURL {
            url = apURL
        }
            
        return AvatarPieceCodable(url: url, name: imageName, width: sizeWidth, height: sizeHeight, positionX: posX, positionY: posY, positionZ: 0, file: imageName)
    }
    
    static func convert(piece: SKAvatarPiece) -> AvatarPiece {
        let avatarPiece = AvatarPiece(context: CoreDataController.instance.mainContext)
        avatarPiece.imageName = piece.getImageName()
        avatarPiece.posX = piece.getRelativePosition().x
        avatarPiece.posY = piece.getRelativePosition().y
        avatarPiece.sizeWidth = piece.getPieceSize().width
        avatarPiece.sizeHeight = piece.getPieceSize().height
        var fileURL: String = ""
        if let resLocalURL = piece.resLocalURL {
            fileURL = resLocalURL
        }
        avatarPiece.file = fileURL
        var url: String = ""
        if let resURL = piece.resURL {
            url = resURL
        }
        avatarPiece.url = url
        return avatarPiece
    }
}
