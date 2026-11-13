//
//  SimulatedPeerModelRepresentation.swift
//  excero
//
//  Created by Alessandro on 06.02.24.
//

import Foundation
class SimulatedPeerModelRepresentation: Representation {
    private var _url: String?
    private var _preview: String?
    private var _avatar: AvatarRepresentation?
    
    public var url: String? {
        get {
            return self._url
        }
        set {
            self._url = newValue
        }
    }
    
    public var preview: String? {
        get {
            return self._preview
        }
    }
    
    public var avatar: AvatarRepresentation? {
        get {
            return self._avatar
        }
        set {
            self._avatar = newValue
        }
    }
    
    internal init(url: String, preview: String, avatar: AvatarRepresentation?) {
        self._url = url
        self._preview = preview
        self._avatar = avatar
    }
}

extension SimulatedPeerModelRepresentation {
    func toCDSimulatedPeerModel() -> SimulatedPeerModel? {
        guard let url = self._url else { return nil }
        guard let preview = self._preview else { return nil }
        
        let sep = SimulatedPeerModel(context: CoreDataController.instance.mainContext)
        sep.url = url
        sep.preview = preview
        if let av = self._avatar, let avatar = av.toCDAvatar(isSelf: false) {
            sep.avatar = avatar
        }
        return sep
    }
    
    static func fromCDSimulatedPeerModel(sep: SimulatedPeerModel) async throws -> SimulatedPeerModelRepresentation? {
        guard let url = sep.url else { return nil }
        guard let preview = sep.preview else { return nil }
        var avatar: AvatarRepresentation?
        
        if let av = sep.avatar {
            avatar = try await AvatarRepresentation.fromCDAvatar(av)
        }
        
        return SimulatedPeerModelRepresentation(url: url, preview: preview, avatar: avatar)
    }
}

extension SimulatedPeerModelRepresentation {
    func toCodable() -> SimulatedPeerModelCodable? {
        guard let url = self._url else { return nil }
        guard let preview = self._preview else { return nil }
        var avatarUrl: String = ""
        if let avatar = self._avatar {
            avatarUrl = avatar.toCodable()?.url ?? ""
        }
        
        return SimulatedPeerModelCodable(url: url, preview: preview, avatar: avatarUrl)
    }
    
    static func fromURL(url: String) async throws -> SimulatedPeerModelRepresentation? {
        let decoder = JSONDecoder()
        let api = AuthenticatedApiFacade()
        let data = try await api.get(fullUrl: url, header: nil)
        if let data = data {
            let representation = try await SimulatedPeerModelRepresentation.fromCodable(sep: try decoder.decode(SimulatedPeerModelCodable.self, from: data))
            return representation
        }
        return nil
    }
    
    static func fromCodable(sep: SimulatedPeerModelCodable) async throws -> SimulatedPeerModelRepresentation? {
        guard let avatar = try await AvatarRepresentation.fromURL(url: sep.avatar.replacingOccurrences(of: "http://", with: "https://")) else { return nil }
        return SimulatedPeerModelRepresentation(url: sep.url, preview: sep.preview, avatar: avatar)
    }
}

extension SimulatedPeerModelRepresentation: CoreDataRepresentable {
    typealias CoreDataElement = SimulatedPeerModel
    typealias RepresentationElement = SimulatedPeerModelRepresentation
    
    static func fromCD(element: SimulatedPeerModel) -> SimulatedPeerModelRepresentation? {
        guard let url = element.url else { return nil }
        guard let preview = element.preview else { return nil }
        
        return SimulatedPeerModelRepresentation(url: url, preview: preview, avatar: nil)
    }
    
    static func fromCD(element: SimulatedPeerModel) async throws -> SimulatedPeerModelRepresentation? {
        guard let url = element.url else { return nil }
        guard let preview = element.preview else { return nil }
        var avatar: AvatarRepresentation?
        
        if let av = element.avatar {
            avatar = try await AvatarRepresentation.fromCDAvatar(av)
        }
        
        return SimulatedPeerModelRepresentation(url: url, preview: preview, avatar: avatar)
    }
    
    func toCD() -> SimulatedPeerModel? {
        guard let url = self._url else { return nil }
        guard let preview = self._preview else { return nil }
        var model: SimulatedPeerModel? = self.checkCoreData {element in element.url == self._url}
        if model == nil {
            model = SimulatedPeerModel(context: CoreDataController.instance.mainContext)
        }
        model?.url = url
        model?.preview = preview
        if let av = self._avatar, let avatar = av.toCDAvatar(isSelf: false) {
            model?.avatar = avatar
        }
        return model
    }
}
