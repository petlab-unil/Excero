//
//  AvatarPieceRepresentation.swift
//  excero
//
//  Created by Alessandro on 02.10.23.
//

import Foundation
import SpriteKit
class AvatarPieceRepresentation {
    private var _url: String?
    private var _imageName: String?
    private var _width: Double?
    private var _height: Double?
    private var _x: Double?
    private var _y: Double?
    private var _z: Double?
    private var _filePath: String?
    private var _type: String?
    
    public var name: String? {
        get {
            return self._imageName
        }
    }
    
    private static let coreModelController: ModelController<AvatarPiece> = ModelController<AvatarPiece>()
    
    public var url: String? {
        get {
            return self._url
        }
    }
    
    internal init(url: String, imageName: String, width: Double, height: Double, x: Double, y: Double, z: Double, filePath: String, type: String) {
        self._url = url
        self._imageName = imageName
        self._width = width
        self._height = height
        self._x = x
        self._y = y
        self._z = z
        self._filePath = filePath
        self._type = type
    }
    
    static func downloadImage(url: String) async throws -> String? {
        guard let httpUrl = URL(string: url.replacingOccurrences(of: "http://", with: "https://")) else { return nil }
        if let data = try? Data(contentsOf: httpUrl) {
            if let img = UIImage(data: data) {
                guard let fileUrl = img.storeSprite(at: .documentDirectory, fileName: httpUrl.deletingPathExtension().lastPathComponent) else { return nil }
                return fileUrl.relativeString
            }
        }
        return nil
    }
    
    static func checkLocalFileExists(url: String) -> Bool {
        guard let path = URL(string: url) else { return false }
        do {
            let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            var finalPath = documents.appendingPathComponent(path.lastPathComponent)
            if !finalPath.absoluteString.contains(".png") {
                finalPath = finalPath.appendingPathExtension("png")
            }
            return FileManager.default.fileExists(atPath: finalPath.path)
        } catch {
            return false
        }
    }
    
    static func getLocalFileURL(url: String) -> String? {
        guard let path = URL(string: url) else { return nil }
        do {
            let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            var finalPath = documents.appendingPathComponent(path.lastPathComponent)
            if !finalPath.absoluteString.contains(".png") {
                finalPath = finalPath.appendingPathExtension("png")
            }
            return finalPath.absoluteString
        } catch {
            return nil
        }
    }
}

extension AvatarPieceRepresentation {
    func toSKAvatarPiece(parentScene: SKScene, forceLocal: Bool = false) async throws -> SKAvatarPiece? {
        guard let url = self._url else { return nil }
        guard let imageName = self._imageName else { return nil }
        guard let width = self._width else { return nil }
        guard let height = self._height else { return nil }
        guard let x = self._x else { return nil }
        guard let y = self._y else { return nil }
        guard let z = self._y else { return nil }
        guard let type = self._type else { return nil }
        var filePath: String = ""
        if let fp = self._filePath {
            if !AvatarPieceRepresentation.checkLocalFileExists(url: fp) {
                if !forceLocal, let dlPath = try await AvatarPieceRepresentation.downloadImage(url: url) {
                    filePath = dlPath
                } else {
                    if let localFilePath = AvatarPieceRepresentation.getLocalFileURL(url: fp) {
                        filePath = localFilePath
                    }
                }
            } else {
                filePath = fp
            }
        } // TODO: Throw Error
        
        let piece = try await SKAvatarPiece(imageName: imageName, size: CGSize(width: width, height: height),
                                  relativePosition: CGPoint(x: x, y: y),
                                            resURL: url, resLocalURL: filePath, zPosition: z)
        return piece
    }
    
    static func fromSKAvatarPiece(piece: SKAvatarPiece) -> AvatarPieceRepresentation? {
        guard let url = piece.resURL else { return nil }
        guard let resLocalUrl = piece.resLocalURL else { return nil }
        return AvatarPieceRepresentation(url: url, imageName: piece.getImageName(),
                                         width: piece.getPieceSize().width, height: piece.getPieceSize().height,
                                         x: piece.getRelativePosition().x, y: piece.getRelativePosition().y, z: piece.z,
                                         filePath: resLocalUrl, type: "")
    }
}

extension AvatarPieceRepresentation {
    func toCDAvatarPiece() -> AvatarPiece? {
        guard let url = self._url else { return nil }
        guard let imageName = self._imageName else { return nil }
        guard let width = self._width else { return nil }
        guard let height = self._height else { return nil }
        guard let x = self._x else { return nil }
        guard let y = self._y else { return nil }
        guard let z = self._z else { return nil }
        guard let filePath = self._filePath else { return nil }
        guard let type = self._type else { return nil }
        var piece: AvatarPiece? = nil
        
        piece = AvatarPieceRepresentation.coreModelController.get(formatString: "url = %@", valueString: url)
        
        if piece == nil {
            piece = AvatarPiece(context: CoreDataController.instance.mainContext)
        }
        piece?.managedObjectContext?.perform {
            piece?.url = url
            piece?.imageName = imageName
            piece?.sizeWidth = width
            piece?.sizeHeight = height
            piece?.posX = x
            piece?.posY = y
            piece?.posZ = z
            piece?.file = filePath
            piece?.type = type
            
            do {
                try CoreDataController.instance.mainContext.save()
            } catch {
                ResourcesManager.logger.error("AvatarPieceRepresentation.toCDAvatarPiece Could not save AvatarPiece. Detailed error: \(error)")
            }
        }
        
        return piece
    }
    
    static func fromCDAvatarPiece(piece: AvatarPiece, downloadMissing: Bool = true) async throws -> AvatarPieceRepresentation? {
        let imageName = piece.managedObjectContext?.performAndWait {
            return piece.imageName
        }
        guard let imageName else { return nil }
        var filePath = piece.managedObjectContext?.performAndWait {
            return piece.file
        }
        guard var filePath else { return nil }
        let url = piece.managedObjectContext?.performAndWait {
            return piece.url
        }
        guard let url else { return nil }
        if downloadMissing && !AvatarPieceRepresentation.checkLocalFileExists(url: filePath) {
            if let dlPath = try await AvatarPieceRepresentation.downloadImage(url: url) {
                filePath = dlPath
            }
        } else {
            if let finalPath = AvatarPieceRepresentation.getLocalFileURL(url: filePath) {
                filePath = finalPath
            }
        }// TODO: Throw Error
        
        return piece.managedObjectContext?.performAndWait {
            return AvatarPieceRepresentation(url: piece.url, imageName: imageName,
                                             width: piece.sizeWidth, height: piece.sizeHeight,
                                             x: piece.posX, y: piece.posY, z: piece.posZ,
                                             filePath: filePath, type: piece.type)
        }
    }
}

extension AvatarPieceRepresentation {
    func toCodable() -> AvatarPieceCodable? {
        guard let url = self._url else { return nil }
        guard let imageName = self._imageName else { return nil }
        guard let width = self._width else { return nil }
        guard let height = self._height else { return nil }
        guard let x = self._x else { return nil }
        guard let y = self._y else { return nil }
        guard let z = self._z else { return nil }
        guard let filePath = self._filePath else { return nil }
        guard let type = self._type else { return nil }
        
        return AvatarPieceCodable(url: url, name: imageName,
                                  width: width, height: height,
                                  positionX: x, positionY: y,
                                  positionZ: z, file: filePath)
    }
    
    static func fromURL(url: String) async throws -> AvatarPieceRepresentation? {
        let decoder = JSONDecoder()
        let api = AuthenticatedApiFacade()
        let data = try await api.get(fullUrl: url, header: nil)
        if let data = data {
            let representation = try await AvatarPieceRepresentation.fromCodable(piece: try decoder.decode(AvatarPieceCodable.self, from: data))
            return representation
        }
        return nil
    }
    
    static func fromCodable(piece: AvatarPieceCodable, downloadMissing: Bool = true) async throws -> AvatarPieceRepresentation? {
        var filePath: String = piece.file
        if downloadMissing && !AvatarPieceRepresentation.checkLocalFileExists(url: piece.file) {
            if let file = try await AvatarPieceRepresentation.downloadImage(url: piece.file) {
                filePath = file
            }
        } else {
            if let file = AvatarPieceRepresentation.getLocalFileURL(url: piece.file) {
                filePath = file
            }
        }
        
        return AvatarPieceRepresentation(url: piece.url, imageName: piece.name,
                                         width: piece.width, height: piece.height,
                                         x: piece.positionX, y: piece.positionY, z: piece.positionZ,
                                         filePath: filePath, type: "")
    }
}
