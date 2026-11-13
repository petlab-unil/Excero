//
//  AvatarController.swift
//  excero
//
//  Created by Alessandro on 09.05.24.
//

import Foundation
import AsyncPlus

class AvatarController {
    
    private let coreAvatarController: ModelController<Avatar>
    private let coreAvatarTypeController: ModelController<AvatarType>
    private let coreAvatarPieceController: ModelController<AvatarPiece>
    
    private let api: AuthenticatedApiFacade
    private let resourceManager: ResourcesManager
    private let prioritizeLocalData: Bool
    
    init(prioritizeLocalData: Bool = false) {
        self.coreAvatarController = ModelController<Avatar>()
        self.coreAvatarTypeController = ModelController<AvatarType>()
        self.coreAvatarPieceController = ModelController<AvatarPiece>()

        self.api = AuthenticatedApiFacade()
        self.resourceManager = ResourcesManager.instance
        self.prioritizeLocalData = prioritizeLocalData
    }
    
    private func categorizeAvatarPiece(_ pieces: [AvatarPieceRepresentation]) -> [AvatarPieceGroup: [AvatarPieceRepresentation]] {
        var result: [AvatarPieceGroup: [AvatarPieceRepresentation]] = [:]
        for piece in pieces {
            var avatarGroup: AvatarPieceGroup?
            if let name = piece.name {
                switch name {
                case _ where name.contains(AvatarPieceGroup.BODY.rawValue):
                    avatarGroup = AvatarPieceGroup.BODY
                case _ where name.contains(AvatarPieceGroup.HAIRS.rawValue):
                    avatarGroup = AvatarPieceGroup.HAIRS
                case _ where name.contains(AvatarPieceGroup.HEAD.rawValue):
                    avatarGroup = AvatarPieceGroup.HEAD
                case _ where name.contains(AvatarPieceGroup.TOP.rawValue):
                    avatarGroup = AvatarPieceGroup.TOP
                case _ where name.contains(AvatarPieceGroup.LEGS.rawValue):
                    avatarGroup = AvatarPieceGroup.LEGS
                case _ where name.contains(AvatarPieceGroup.SHOES.rawValue):
                    avatarGroup = AvatarPieceGroup.SHOES
                default:
                    continue
                }
            }
            if let avatarGroup {
                if result[avatarGroup] == nil {
                    result[avatarGroup] = [piece]
                } else {
                    result[avatarGroup]!.append(piece)
                }
            }
        }
        return result
    }
    
    
    func getAvatarTypes() async -> [AvatarTypeRepresentation]? {
        var types: [AvatarTypeRepresentation]? = nil
        if self.prioritizeLocalData {
            let dbTypes = self.coreAvatarTypeController.list()
            do {
                types = []
                for type in dbTypes {
                    if let representation = try await AvatarTypeRepresentation.fromCD(element: type) {
                        if var types {
                            types.append(representation)
                        }
                    }
                }
                return types
            } catch {
                print("Error while getting local types: \(error)")
            }
        }
        if (types == nil || types?.count == 0) && self.resourceManager.networkAvailable {
                return await attempt {
                    return try await self.api.get(endpointPath: "avatartypes/", header: nil)
                }.then { (data: Data?) -> [AvatarTypeRepresentation]? in
                    if let data {
                        let decoder = JSONDecoder()
                        do {
                            let results = try decoder.decode([AvatarTypeCodable].self, from: data)
                            var types: [AvatarTypeRepresentation] = []
                            for result in results {
                                if let type = try await AvatarTypeRepresentation.fromCodable(element: result) {
                                    types.append(type)
                                }
                            }
                            return types
                        } catch {
                            fatalError("Could not load avatar types: \(error)")
                        }
                    }
                    return nil
                }.asyncOptional() ?? nil
            }
        return types
    }
    
    func getAvatarPieces() async -> [AvatarPieceGroup: [AvatarPieceRepresentation]]? {
        var representations: [AvatarPieceRepresentation] = []
        if self.prioritizeLocalData {
            let dbPieces = self.coreAvatarPieceController.list()
            do {
                for piece in dbPieces {
                    if let rep = try await AvatarPieceRepresentation.fromCDAvatarPiece(piece: piece) {
                        representations.append(rep)
                    }
                }
            } catch {
                print("Could not load local database from ")
            }
        }
        
        if representations.count == 0 && self.resourceManager.networkAvailable {
            return await attempt {
                return try await self.api.get(endpointPath: "avatarpieces/", header: nil)
            }.then { (data: Data?) -> [AvatarPieceGroup: [AvatarPieceRepresentation]]? in
                guard let data = data else { return nil }
                do {
                    let decoder = JSONDecoder()
                    let pieces = try decoder.decode([AvatarPieceCodable].self, from: data)
                    var representations: [AvatarPieceRepresentation] = []
                    for piece in pieces {
                        if let rep = try await AvatarPieceRepresentation.fromCodable(piece: piece) {
                            representations.append(rep)
                        }
                    }
                    return self.categorizeAvatarPiece(representations)
                } catch {
                    fatalError("Error while retrieving avatar pieces: \(error)")
                }
            }.asyncOptional() ?? nil
        }
        if representations.count > 0 {
            return self.categorizeAvatarPiece(representations)
        }
        return nil
    }
    
    
    func getAvatar(user: UserRepresentation) async -> AvatarRepresentation? {
        var avatar: AvatarRepresentation? = nil
        if self.prioritizeLocalData {
            if let dbAvatar = self.coreAvatarController.executePredicate(NSPredicate(format: "user.url == %@", user.url ?? "")), let last = dbAvatar.last {
                do {
                    avatar = try await AvatarRepresentation.fromCDAvatar(last)
                } catch {
                    fatalError("Could not convert local avatar to representation: \(error)")
                }
            }
            if self.resourceManager.networkAvailable {
                Task {
                    var avatar: AvatarRepresentation?
                    avatar = await attempt {
                        if let userURL = user.url {
                            return try await self.api.get(fullUrl: userURL + "avatars/", header: nil)
                        }
                        return nil
                    }.then { (data: Data?) -> AvatarRepresentation? in
                        guard let data = data else {return nil}
                        let decoder = JSONDecoder()
                        do {
                            let avatars = try decoder.decode([AvatarCodable].self, from: data)
                            if let avatar = avatars.last {
                                return await AvatarRepresentation.fromCodable(avatar)
                            } else {
                                return nil
                            }
                        } catch {
                            fatalError("Error while decoding avatar: \(error)")
                        }
                        
                    }.asyncOptional() ?? nil
                    if let avatar {
                        let _ = avatar.toCDAvatar(isSelf: user.url == self.resourceManager.user?.url, user: user)
                    }
                }
            }
        }
        
        if avatar == nil && self.resourceManager.networkAvailable {
            avatar = await attempt {
                if let userURL = user.url {
                    return try await self.api.get(fullUrl: userURL + "avatars/", header: nil)
                }
                return nil
            }.then { (data: Data?) -> AvatarRepresentation? in
                guard let data = data else {return nil}
                let decoder = JSONDecoder()
                do {
                    let avatars = try decoder.decode([AvatarCodable].self, from: data)
                    if let avatar = avatars.last {
                        return await AvatarRepresentation.fromCodable(avatar)
                    } else {
                        return nil
                    }
                } catch {
                    fatalError("Error while decoding avatar: \(error)")
                }
                
            }.asyncOptional() ?? nil
            if let avatar {
                let _ = avatar.toCDAvatar(isSelf: user.url == self.resourceManager.user?.url, user: user)
            }
        }
        return avatar
    }
    
    func getAvatar(sep: SimulatedPeerModelRepresentation) async -> AvatarRepresentation? {
        var avatar: AvatarRepresentation? = nil
        if self.prioritizeLocalData {
            if let dbAvatar = self.coreAvatarController.executePredicate(NSPredicate(format: "simulatedPeerModel.url == %@", sep.url ?? "")), let last = dbAvatar.last {
                do {
                    avatar = try await AvatarRepresentation.fromCDAvatar(last)
                } catch {
                    fatalError("Could not convert local avatar to representation: \(error)")
                }
            }
            
            if self.resourceManager.networkAvailable {
                Task {
                    var avatar: AvatarRepresentation? = nil
                    avatar = await attempt {
                        if let sepURL = sep.avatar?.url {
                            return try await self.api.get(fullUrl: sepURL, header: nil)
                        }
                        return nil
                    }.then { (data: Data?) -> AvatarRepresentation? in
                        guard let data = data else {return nil}
                        let decoder = JSONDecoder()
                        do {
                            let avatar = try decoder.decode(AvatarCodable.self, from: data)
                            return await AvatarRepresentation.fromCodable(avatar)
                        } catch {
                            fatalError("Error while decoding avatar: \(error)")
                        }
                        
                    }.asyncOptional() ?? nil
                    if let avatar {
                        let _ = avatar.toCDAvatar(isSelf: false, sep: sep)
                    }
                }
            }
        }
        
        if avatar == nil && self.resourceManager.networkAvailable {
            avatar = await attempt {
                if let sepURL = sep.avatar?.url {
                    return try await self.api.get(fullUrl: sepURL, header: nil)
                }
                return nil
            }.then { (data: Data?) -> AvatarRepresentation? in
                guard let data = data else {return nil}
                let decoder = JSONDecoder()
                do {
                    let avatar = try decoder.decode(AvatarCodable.self, from: data)
                    return await AvatarRepresentation.fromCodable(avatar)
                } catch {
                    fatalError("Error while decoding avatar: \(error)")
                }
                
            }.asyncOptional() ?? nil
            if let avatar {
                let _ = avatar.toCDAvatar(isSelf: false, sep: sep)
            }
        }
        return avatar
    }
    
    func getAvatarPiecesWithType(type: AvatarTypeRepresentation) async -> [AvatarPieceGroup: [AvatarPieceRepresentation]]? {
        var categorizedPieces: [AvatarPieceGroup: [AvatarPieceRepresentation]]? = nil
        if self.prioritizeLocalData {
            let dbTypes = self.coreAvatarTypeController.list()
            for dbType in dbTypes {
                if type.name == dbType.name {
                    var representations: [AvatarPieceRepresentation] = []
                    do {
                        if let dbPieces = dbType.pieces {
                            for piece in dbPieces {
                                if let rep = try await AvatarPieceRepresentation.fromCDAvatarPiece(piece: piece as! AvatarPiece) {
                                    representations.append(rep)
                                }
                            }
                            categorizedPieces = self.categorizeAvatarPiece(representations)
                        }
                    } catch {
                        fatalError("Could not load local database from ")
                    }
                }
            }
        }
        
        if (categorizedPieces == nil || categorizedPieces?.count == 0) && self.resourceManager.networkAvailable {
            categorizedPieces = await attempt {
                guard let typeURL = type.url else {return nil}
                return try await self.api.get(fullUrl: typeURL + "pieces/", header: nil)
            }.then { (data: Data?) -> [AvatarPieceGroup: [AvatarPieceRepresentation]]? in
                guard let data = data else { return nil }
                do {
                    let decoder = JSONDecoder()
                    let pieces = try decoder.decode([AvatarPieceCodable].self, from: data)
                    var representations: [AvatarPieceRepresentation] = []
                    for piece in pieces {
                        if let rep = try await AvatarPieceRepresentation.fromCodable(piece: piece) {
                            representations.append(rep)
                        }
                    }
                    return self.categorizeAvatarPiece(representations)
                } catch {
                    fatalError("Error while retrieving avatar pieces: \(error)")
                }
            }.asyncOptional() ?? nil
        }
        return categorizedPieces
    }
    
    func getAvatarTypeWithURL(url: String) async -> AvatarTypeRepresentation? {
        var type: AvatarTypeRepresentation? = nil
        if self.prioritizeLocalData {
            if let types = self.coreAvatarTypeController.executePredicate(NSPredicate(format: "url == %@", url)), let last = types.last {
                do {
                    type = try await AvatarTypeRepresentation.fromCD(element: last)
                } catch {
                    fatalError("Error while retrieving avatar type from url using local db: \(error)")
                }
            }
        }
        
        if type == nil && self.resourceManager.networkAvailable {
            type = await attempt {
                return try await self.api.get(fullUrl: url, header: nil)
            }.then { (data: Data?) -> AvatarTypeRepresentation? in
                guard let data = data else { return nil }
                let decoder = JSONDecoder()
                do {
                    let decoded = try decoder.decode(AvatarTypeCodable.self, from: data)
                    return try await AvatarTypeRepresentation.fromCodable(element: decoded)
                } catch {
                    fatalError("Error while retrieving avatar type from url: \(error)")
                }
            }.asyncOptional() ?? nil
        }
        return type
    }
    
    func createAvatar(_ avatar: AvatarRepresentation, user: UserRepresentation) async -> AvatarRepresentation? {
        var coreDataAvatar: Avatar?
        if let avatarURL = avatar.url, let avatars = self.coreAvatarController.executePredicate(NSPredicate(format: "url == %@", avatarURL)),
           let last = avatars.last {
            coreDataAvatar = last
        }
        if coreDataAvatar == nil {
            coreDataAvatar = avatar.toCDAvatar(isSelf: true)
        } else {
            if let tint = avatar.tint {
                coreDataAvatar?.tint = tint
            }
            var coreDataHairsPiece: AvatarPiece?
            var coreDataHeadPiece: AvatarPiece?
            var coreDataBasePiece: AvatarPiece?
            var coreDataTopPiece: AvatarPiece?
            var coreDataLegsPiece: AvatarPiece?
            var coreDataShoesPiece: AvatarPiece?
            if let hairs = avatar.hairs, let url = hairs.url, let pieces = self.coreAvatarPieceController.executePredicate(NSPredicate(format: "url == %@", url)),
               let last = pieces.last {
                coreDataHairsPiece = last
            } else {
                coreDataHairsPiece = avatar.hairs?.toCDAvatarPiece()
            }
            if let head = avatar.head, let url = head.url, let pieces = self.coreAvatarPieceController.executePredicate(NSPredicate(format: "url == %@", url)),
               let last = pieces.last {
                coreDataHeadPiece = last
            } else {
                coreDataHeadPiece = avatar.head?.toCDAvatarPiece()
            }
            if let top = avatar.top, let url = top.url, let pieces = self.coreAvatarPieceController.executePredicate(NSPredicate(format: "url == %@", url)),
               let last = pieces.last {
                coreDataTopPiece = last
            } else {
                coreDataTopPiece = avatar.top?.toCDAvatarPiece()
            }
            if let legs = avatar.legs, let url = legs.url, let pieces = self.coreAvatarPieceController.executePredicate(NSPredicate(format: "url == %@", url)),
               let last = pieces.last {
                coreDataLegsPiece = last
            } else {
                coreDataLegsPiece = avatar.legs?.toCDAvatarPiece()
            }
            if let shoes = avatar.shoes, let url = shoes.url, let pieces = self.coreAvatarPieceController.executePredicate(NSPredicate(format: "url == %@", url)),
               let last = pieces.last {
                coreDataShoesPiece = last
            } else {
                coreDataShoesPiece = avatar.shoes?.toCDAvatarPiece()
            }
            coreDataAvatar?.hairs = coreDataHairsPiece
            coreDataAvatar?.head = coreDataHeadPiece
            coreDataAvatar?.base = coreDataBasePiece
            coreDataAvatar?.shirt = coreDataTopPiece
            coreDataAvatar?.trousers = coreDataLegsPiece
            coreDataAvatar?.shoes = coreDataShoesPiece
        }
        
        if self.resourceManager.networkAvailable {
            guard let userURL = user.url else { return nil }
            return await attempt {
                guard let avatarCodable = avatar.toCodable() else { return nil }
                return try await self.api.post(fullUrl: userURL + "avatars/", data: avatarCodable, header: nil)
            }.then { (data:Data?) -> AvatarRepresentation? in
                guard let data = data else { return nil }
                let decoder = JSONDecoder()
                do {
                    let avatar = try decoder.decode(AvatarCodable.self, from: data)
                    return await AvatarRepresentation.fromCodable(avatar)
                } catch {
                    fatalError("Error while retrieving results of avatar creation request: \(error)")
                }
                return nil
            }.asyncOptional() ?? nil
        } 
        return nil
    }
    
}
