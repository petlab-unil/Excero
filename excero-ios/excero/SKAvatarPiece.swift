//
//  AvatarPiece.swift
//  excero
//
//  Created by Alessandro Silacci on 10.08.22.
//

import Foundation
import SpriteKit


class SKAvatarPiece: SKSpriteNode {
    enum SKAvatarPieceError: Error {
        case FileDoesNotExistLocallyError(String)
    }
    private var relativeScale: CGFloat
    private var relativePosition: CGPoint
    private var imageName: String
    private var pieceSize: CGSize
    
    private var _resLocalURL: String?
    private var _resURL: String?
    
    var resURL: String? {
        set {
            self._resURL = newValue
        }
        get { return self._resURL }
    }
    
    var resLocalURL: String? {
        set {
            self._resLocalURL = newValue
        }
        get { return self._resLocalURL }
    }
    
    var z : CGFloat {
        get {
            return self.zPosition
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        self.relativeScale = 0.0
        self.relativePosition = CGPoint(x: 0.0, y: 0.0)
        self.imageName = ""
        self.pieceSize = CGSize(width: 0, height: 0)
        
        super.init(coder: aDecoder)
    }
    
    internal init(imageName: String, relativeScale: CGFloat, relativePosition: CGPoint, resLocalURL: String?, zPosition: CGFloat? = nil) throws {
        
        self.relativeScale = relativeScale
        self.relativePosition = relativePosition
        self.imageName = imageName
        self.pieceSize = CGSize(width: 0, height: 0)
        var textureLocalURL = ""
        if let res = resLocalURL {
            textureLocalURL = res
        }
        let img = UIImage(fileURL: URL(string: textureLocalURL)!)
        guard let pieceImage = img else {
            super.init(texture: nil, color: UIColor.clear, size: CGSize(width: 0, height: 0))
            return
        }
        let texture = SKTexture(image: pieceImage)
        super.init(texture: texture, color: UIColor.clear, size: texture.size())
        
        self.setScale(self.relativeScale)
        self.position = relativePosition
        self._resLocalURL = resLocalURL
        self.zPosition = zPosition ?? 0
    }
    
    internal init(imageName: String, size: CGSize, relativePosition: CGPoint, resLocalURL: String?, zPosition: CGFloat? = nil) throws {
        self.relativeScale = 1.0
        self.relativePosition = relativePosition
        self.imageName = imageName
        self.pieceSize = size
        var img: UIImage?
        if let res = resLocalURL {
            img = try SKAvatarPiece.loadImageFromLocalURL(resourceURL: "",textureLocalURL: res)
        }
        guard let pieceImage = img else {
            super.init(texture: nil, color: UIColor.clear, size: CGSize(width: 0, height: 0))
            return
        }
        let texture = SKTexture(image: pieceImage)
        super.init(texture: texture, color: UIColor.clear, size: size)
        
        self.setScale(self.relativeScale)
        self.position = relativePosition
        self._resLocalURL = resLocalURL
        self.zPosition = zPosition ?? 0
    }
    
    internal init(imageName: String, size: CGSize, relativePosition: CGPoint, resURL: String, resLocalURL: String?, zPosition: CGFloat? = nil) throws { // TODO: refactor
        self.relativeScale = 1.0
        self.relativePosition = relativePosition
        self.imageName = imageName
        self.pieceSize = size
        
        var img: UIImage?
        if let res = resLocalURL {
            img = try SKAvatarPiece.loadImageFromLocalURL(resourceURL: resURL, textureLocalURL: res)
        }
        guard let pieceImage = img else {
            super.init(texture: nil, color: UIColor.clear, size: CGSize(width: 0, height: 0))
            return
        }
        let texture = SKTexture(image: pieceImage)
        super.init(texture: texture, color: UIColor.clear, size: size)
        
        self.setScale(self.relativeScale)
        self.position = relativePosition
        self._resURL = resURL
        self._resLocalURL = resLocalURL
        self.zPosition = zPosition ?? 0
    }
    
    internal init(imageName: String, size: CGSize, relativePosition: CGPoint, zPosition: CGFloat? = nil) {
        self.relativeScale = 1.0
        self.relativePosition = relativePosition
        self.imageName = imageName
        self.pieceSize = size
        
        let texture = SKTexture(image: UIImage(named: imageName)!)
        super.init(texture: texture, color: UIColor.clear, size: size)
        self.zPosition = zPosition ?? 0
    }
    
    private static func loadImageFromLocalURL(resourceURL: String, textureLocalURL: String) throws -> UIImage {
        guard let path = URL(string: textureLocalURL) else {
            print("Could not create path.")
            return UIImage(named: "")! // FIXME: Source file is empty.
        }
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path.path) {
        } else {
            throw SKAvatarPieceError.FileDoesNotExistLocallyError(resourceURL)
        }
        do {
            let img = UIImage(fileURL: URL(string: textureLocalURL)!)
            if let img = img {
                return img
            }
        } catch {
            throw SKAvatarPieceError.FileDoesNotExistLocallyError(resourceURL)
        }
        throw SKAvatarPieceError.FileDoesNotExistLocallyError(resourceURL)
    }
    
    func getRelativeScale() -> CGFloat {
        return self.relativeScale
    }
    
    func getRelativePosition() -> CGPoint {
        return self.relativePosition
    }
    
    func getImageName() -> String {
        return self.imageName
    }
    
    func getPieceSize() -> CGSize {
        return self.pieceSize
    }
    
    override func copy() -> Any {
        do {
            return try SKAvatarPiece(imageName: self.imageName, size: self.pieceSize, relativePosition: self.relativePosition,  resLocalURL: self._resLocalURL, zPosition: self.zPosition)
        } catch {
            print("Error while copying SKAvatarPiece")
        }
        return SKAvatarPiece(imageName: self.imageName, size: self.pieceSize, relativePosition: self.relativePosition)
    }
}
