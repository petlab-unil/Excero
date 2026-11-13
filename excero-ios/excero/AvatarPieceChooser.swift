//
//  AvatarPieceChooser.swift
//  excero
//
//  Created by Alessandro Silacci on 12.08.22.
//

import Foundation
import SpriteKit

class AvatarPieceChooser {
    private var parentScene: SKScene
    private var buttonPrevious: SKSpriteNode
    private var buttonNext: SKSpriteNode
    private var avatarPieces: Array<SKAvatarPiece>
    private var position: CGPoint
    private var scale: CGFloat
    private var avatar: SKAvatar?
    private var startPosition: CGPoint
    private var endPosition: CGPoint
    private var pieceZPosition: CGFloat = 900
    private var ratio: CGSize
    
    private var chooserAnimationSpeed: Double = 0.8
    
    private var additionalMetadata: [Any]?
    
    private var currentIndex: Int = 0
    
    internal init(avatarPieces: Array<SKAvatarPiece>, position: CGPoint, parentScene: SKScene, avatar: SKAvatar, ratio: CGSize,
                  scale: CGFloat, startPosition: CGPoint, endPosition: CGPoint, previousSpriteName: String?, nextSpriteName: String?,
                  pieceZPosition: CGFloat?, additionalMetadata: [Any]? = nil) {
        self.avatarPieces = avatarPieces
        self.position = position
        self.parentScene = parentScene
        self.scale = scale
        self.avatar = avatar
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.ratio = ratio
        if let zPos = pieceZPosition {
            self.pieceZPosition = zPos
        }
        
        var texturePrevious = SKTexture(imageNamed: "ui_chevron")
        if let previousSprite = previousSpriteName {
            texturePrevious = SKTexture(imageNamed: previousSprite)
        }
        self.buttonPrevious = SKSpriteNode(texture: texturePrevious, size: CGSize(width: 50 * ratio.width, height: 50 * ratio.height))
        self.buttonPrevious.name = UUID().uuidString
        
        var textureNext = SKTexture(imageNamed: "ui_chevron")
        if let nextSprite = nextSpriteName {
            textureNext = SKTexture(imageNamed: nextSprite)
        }
        self.buttonNext = SKSpriteNode(texture: textureNext, size: CGSize(width: 50 * ratio.width, height: 50 * ratio.height))
        self.buttonNext.zRotation = .pi
        self.buttonNext.name = UUID().uuidString
        
        self.buttonNext.position = CGPoint(x: self.position.x - 50 * ratio.width, y: position.y * ratio.height)
        self.buttonPrevious.position = CGPoint(x: (-1 * self.position.x) + 50 * ratio.width, y: position.y * ratio.height)
        self.initCustomizer(piece: self.avatarPieces[self.currentIndex])
        self.additionalMetadata = additionalMetadata
    }
    
    internal init(avatarPieces: Array<SKAvatarPiece>, position: CGPoint, parentScene: SKScene, ratio: CGSize,
                  scale: CGFloat, startPosition: CGPoint, endPosition: CGPoint, previousSpriteName: String?, nextSpriteName: String?,
                  pieceZPosition: CGFloat?, additionalMetadata: [Any]? = nil) {
        self.avatarPieces = avatarPieces
        self.position = position
        self.parentScene = parentScene
        self.scale = scale
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.ratio = ratio
        if let zPos = pieceZPosition {
            self.pieceZPosition = zPos
        }
        
        var texturePrevious = SKTexture(imageNamed: "ui_chevron")
        if let previousSprite = previousSpriteName {
            texturePrevious = SKTexture(imageNamed: previousSprite)
        }
        self.buttonPrevious = SKSpriteNode(texture: texturePrevious, size: CGSize(width: 50 * ratio.width, height: 50 * ratio.height))
        self.buttonPrevious.name = UUID().uuidString
        
        var textureNext = SKTexture(imageNamed: "ui_chevron")
        if let nextSprite = nextSpriteName {
            textureNext = SKTexture(imageNamed: nextSprite)
        }
        self.buttonNext = SKSpriteNode(texture: textureNext, size: CGSize(width: 50 * ratio.width, height: 50 * ratio.height))
        self.buttonNext.zRotation = .pi
        self.buttonNext.name = UUID().uuidString
        
        self.buttonNext.position = CGPoint(x: self.position.x - 50 * ratio.width, y: position.y * ratio.height)
        self.buttonPrevious.position = CGPoint(x: (-1 * self.position.x) + 50 * ratio.width, y: position.y * ratio.height)
        self.initCustomizer(piece: self.avatarPieces[self.currentIndex])
        self.additionalMetadata = additionalMetadata
    }
    
    private func removePreviousPiece(pieces: Array<SKAvatarPiece>, index: Int, forward: Bool) {
        if forward {
            let piece: SKAvatarPiece?
            if index > 0 {
                piece = pieces[index-1]
            } else {
                piece = pieces[pieces.count-1]
            }
            if let p = piece {
                let animation = SKAction.moveTo(x: self.endPosition.x, duration: self.chooserAnimationSpeed)
                animation.timingMode = SKActionTimingMode.easeInEaseOut
                let completion = SKAction.run {
                    p.removeFromParent()
                }
                let action = SKAction.sequence([animation, completion])
                p.run(action)
            }
        } else {
            let piece: SKAvatarPiece?
            if index == pieces.count - 1 {
                piece = pieces[0]
            } else {
                piece = pieces[index+1]
            }
            if let p = piece {
                let animation = SKAction.moveTo(x: self.startPosition.x, duration: self.chooserAnimationSpeed)
                animation.timingMode = SKActionTimingMode.easeInEaseOut
                let completion = SKAction.run {
                    p.removeFromParent()
                }
                let action = SKAction.sequence([animation, completion])
                p.run(action)
            }
        }
    }
    
    func initCustomizer(piece: SKAvatarPiece) {
        let finalPiecePosition = piece.getRelativePosition()
        piece.setScale(self.ratio.height)
        piece.zPosition = self.pieceZPosition
        if let avatar = self.avatar {
            piece.position = CGPoint(x: finalPiecePosition.x,
                                     y: avatar.getBasePosition().y + (finalPiecePosition.y * (self.ratio.height)))
        } else {
            piece.position = CGPoint(x: finalPiecePosition.x,
                                     y: (finalPiecePosition.y * (self.ratio.height)))
        }
        self.parentScene.addChild(piece)
    }
    
    
    func callNext() -> Void {
        if self.currentIndex < self.avatarPieces.count - 1 {
            self.currentIndex += 1
        } else {
            self.currentIndex = 0
        }
        let piece = self.avatarPieces[self.currentIndex]
        if self.parentScene.children.contains(piece) { return }
        let finalPiecePosition = piece.getRelativePosition()
        piece.setScale(self.ratio.height)
        piece.zPosition = self.pieceZPosition
        if let avatar = self.avatar {
            /*piece.position = CGPoint(x: self.startPosition.x,
                                     y: avatar.getBasePosition().y +
                                     (finalPiecePosition.y * (self.scale)))*/
            piece.position = CGPoint(x: self.startPosition.x,
                                     y: avatar.getBasePosition().y +
                                     (finalPiecePosition.y * (self.ratio.height)))
        } else {
            /*piece.position = CGPoint(x: self.startPosition.x,
                                     y: (finalPiecePosition.y * (self.scale)))*/
            piece.position = CGPoint(x: self.startPosition.x,
                                     y: (finalPiecePosition.y * (self.ratio.height)))
        }
        self.parentScene.addChild(piece)
        self.removePreviousPiece(pieces: self.avatarPieces, index: self.currentIndex, forward: true)
        let animation = SKAction.moveTo(x: finalPiecePosition.x, duration: self.chooserAnimationSpeed)
        animation.timingMode = SKActionTimingMode.easeInEaseOut
        piece.run(animation)
    }
    
    func callPrevious() -> Void {
        if self.currentIndex > 0 {
            self.currentIndex -= 1
        } else {
            self.currentIndex = self.avatarPieces.count - 1
        }
        let piece = self.avatarPieces[self.currentIndex]
        if self.parentScene.children.contains(piece) { return }
        let finalPiecePosition = piece.getRelativePosition()
        piece.setScale(self.ratio.height)
        if let avatar = self.avatar {
            piece.position = CGPoint(x: self.endPosition.x,
                                     y: avatar.getBasePosition().y + (finalPiecePosition.y * (self.ratio.height)))
        } else {
            piece.position = CGPoint(x: self.endPosition.x,
                                     y: (finalPiecePosition.y * (self.ratio.height)))
        }
        piece.zPosition = self.pieceZPosition
        self.removePreviousPiece(pieces: self.avatarPieces, index: self.currentIndex, forward: false)
        
        self.parentScene.addChild(piece)
        let animation = SKAction.moveTo(x: finalPiecePosition.x, duration: self.chooserAnimationSpeed)
        animation.timingMode = SKActionTimingMode.easeInEaseOut
        piece.run(animation)
    }
    
    func spawnControls() {
        self.parentScene.addChild(self.buttonNext)
        self.parentScene.addChild(self.buttonPrevious)
    }
    
    func removeControls() {
        self.parentScene.removeChildren(in: [self.buttonNext, self.buttonPrevious, self.avatarPieces[self.currentIndex]])
    }
    
    func getPreviousID() -> String? {
        return self.buttonPrevious.name
    }
    
    func getNextID() -> String? {
        return self.buttonNext.name
    }
    
    func getCurrentSelection() -> SKAvatarPiece {
        return self.avatarPieces[self.currentIndex]
    }
    
    func getCurrentMetadata() -> Any? {
        return self.additionalMetadata?[self.currentIndex]
    }
}
