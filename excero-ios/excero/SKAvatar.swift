//
//  Avatar.swift
//  excero
//
//  Created by Alessandro Silacci on 10.08.22.
//

import Foundation
import SpriteKit
class SKAvatar {
    private var _base: SKAvatarPiece
    private var _head: SKAvatarPiece?
    private var _hairs: SKAvatarPiece?
    private var _shirt: SKAvatarPiece?
    private var _trousers: SKAvatarPiece?
    private var _shoes: SKAvatarPiece?
    
    private var parentScene: SKScene
    
    var base: SKAvatarPiece {
        get {
            return self._base
        }
        set {
            self._base = newValue
            self._base.zPosition = 1
        }
    }
    
    var head: SKAvatarPiece? {
        get {
            return self._head
        }
        set {
            self._head = newValue
        }
    }
    
    var hairs: SKAvatarPiece? {
        get {
            return self._hairs
        }
        set {
            self._hairs = newValue
            self._hairs?.zPosition = 5
        }
    }
    
    var shirt: SKAvatarPiece? {
        get {
            return self._shirt
        }
        set {
            self._shirt = newValue
            self._shirt?.zPosition = 4
        }
    }
    
    var trousers: SKAvatarPiece? {
        get {
            return self._trousers
        }
        set {
            self._trousers = newValue
            self._trousers?.zPosition = 3
        }
    }
    
    var shoes: SKAvatarPiece? {
        get {
            return self._shoes
        }
        set {
            self._shoes = newValue
            self._shoes?.zPosition = 2
        }
    }
    
    internal init(base: SKAvatarPiece,
                  head: SKAvatarPiece?,
                  hairs: SKAvatarPiece?,
                  shirt: SKAvatarPiece?,
                  trousers: SKAvatarPiece?,
                  shoes: SKAvatarPiece?,
                  parentScene: SKScene) {
        self.parentScene = parentScene
        self._base = base
        self._base.zPosition = 1
        
        if let head = head {
            self._head = head
        }
        if let hairs = hairs {
            self._hairs = hairs
            self._hairs!.zPosition = 5
        }
        if let shirt = shirt {
            self._shirt = shirt
            self._shirt!.zPosition = 4
        }
        if let trousers = trousers {
            self._trousers = trousers
            self._trousers!.zPosition = 3
        }
        if let shoes = shoes {
            self._shoes = shoes
            self._shoes!.zPosition = 2
        }
    }
    
    func spawn(basePosition: CGPoint? = nil) {
        
        if let basePosition {
            self.base.position = basePosition
        }
        
        self.parentScene.addChild(self.base)
        
        if let head = self._head {
            self._base.addChild(head)
        }
        
        if let hairs = self._hairs {
            self._base.addChild(hairs)
        }
        
        if let shirt = self._shirt {
            self._base.addChild(shirt)
        }
        
        if let trousers = self._trousers {
            self._base.addChild(trousers)
        }
        
        if let shoes = self._shoes {
            self._base.addChild(shoes)
        }
    }
    
    func createSpriteNode() -> SKSpriteNode{
        //self.parentScene.addChild(self.base)
        let base = self.base.copy() as! SKSpriteNode
        base.color = self.base.color
        base.colorBlendFactor = self.base.colorBlendFactor
        if let head = self._head {
            base.addChild(head.copy() as! SKSpriteNode)
        }
        
        if let hairs = self._hairs {
            base.addChild(hairs.copy() as! SKSpriteNode)
        }
        
        if let shirt = self._shirt {
            base.addChild(shirt.copy() as! SKSpriteNode)
        }
        
        if let trousers = self._trousers {
            base.addChild(trousers.copy() as! SKSpriteNode)
        }
        
        if let shoes = self._shoes {
            base.addChild(shoes.copy() as! SKSpriteNode)
        }
        let merge = SKView().texture(from: base)
        return SKSpriteNode(texture: merge)
    }
    
    func getBaseSize() -> CGSize {
        return self.base.size
    }
    
    func getBasePosition() -> CGPoint {
        return self.base.position
    }
    
    func getBase() -> SKAvatarPiece? {
        return self.base
    }
    
    func getHead() -> SKAvatarPiece? {
        return self.head
    }
    
    func getHairs() -> SKAvatarPiece? {
        return self._hairs
    }
    
    func getShirt() -> SKAvatarPiece? {
        return self._shirt
    }
    
    func getTrousers() -> SKAvatarPiece? {
        return self._trousers
    }
    
    func getShoes() -> SKAvatarPiece? {
        return self._shoes
    }
    
    func setPosition(pos: CGPoint) {
        self.base.position = pos
    }
    
    func removeFromScene() {
        var toRemove: [SKAvatarPiece] = []
        toRemove.append(self._base)
        if let hairs = self._hairs {
            toRemove.append(hairs)
        }
        if let head = self._head {
            toRemove.append(head)
        }
        if let top = self._shirt {
            toRemove.append(top)
        }
        if let legs = self._trousers {
            toRemove.append(legs)
        }
        if let shoes = self._shoes {
            toRemove.append(shoes)
        }
        self.parentScene.removeChildren(in: toRemove)
    }
    
}

extension SKAvatar {
    func toImage() -> UIImage? {
        guard let textureCGImage = self.createSpriteNode().texture?.cgImage() else {return nil}
        let image = UIImage(cgImage: textureCGImage)
        let data = image.pngData()
        return UIImage(data: data!)
    }
}
