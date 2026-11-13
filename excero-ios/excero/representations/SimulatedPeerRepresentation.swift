//
//  SimulatedPeerRepresentation.swift
//  excero
//
//  Created by Alessandro on 03.10.23.
//

import Foundation
import CryptoKit
class SimulatedPeerRepresentation: Representation {
    private var _url: String?
    private var _name: String?
    private var _model: SimulatedPeerModelRepresentation?
    
    private static let coreModelController: ModelController<SimulatedPeer> = ModelController<SimulatedPeer>()
    
    public var url: String? {
        get {
            return self._url
        }
    }
    
    public var model: SimulatedPeerModelRepresentation? {
        get {
            return self._model
        }
    }
    
    public var name: String? {
        get {
            return self._name
        }
    }
    
    public var nameHash: String? {
        get {
            if let name = self._name {
                return SHA256.hash(data: Data(name.utf8)).compactMap { String(format: "%02x", $0) }.joined()
            }
            return nil
        }
    }
    
    internal init(url: String, name: String, model: SimulatedPeerModelRepresentation?) {
        self._url = url
        self._name = name
        self._model = model
    }
}

extension SimulatedPeerRepresentation {
    func toCodable() -> SimulatedPeerCodable? {
        guard let url = self._url else { return nil }
        guard let name = self._name else { return nil }
        var modelUrl: String?
        if let model = self._model {
            modelUrl = model.toCodable()?.url
        }
        
        return SimulatedPeerCodable(url: url, name: name, model: modelUrl)
    }
    
    static func fromURL(url: String) async throws -> SimulatedPeerRepresentation? {
        let decoder = JSONDecoder()
        let api = AuthenticatedApiFacade()
        let data = try await api.get(fullUrl: url, header: nil)
        if let data = data {
            let representation = try await SimulatedPeerRepresentation.fromCodable(sep: try decoder.decode(SimulatedPeerCodable.self, from: data))
            return representation
        }
        return nil
    }
    
    static func fromCodable(sep: SimulatedPeerCodable) async throws -> SimulatedPeerRepresentation? {
        guard let modelUrl = sep.model, let model = try await SimulatedPeerModelRepresentation.fromURL(url: modelUrl.replacingOccurrences(of: "http://", with: "https://")) else { return nil }
        return SimulatedPeerRepresentation(url: sep.url, name: sep.name, model: model)
    }
}

extension SimulatedPeerRepresentation: CoreDataRepresentable {
    typealias CoreDataElement = SimulatedPeer
    typealias RepresentationElement = SimulatedPeerRepresentation
    
    static func fromCD(element: SimulatedPeer) -> SimulatedPeerRepresentation? {
        guard let url = element.url else { return nil }
        guard let name = element.name else { return nil }

        
        return SimulatedPeerRepresentation(url: url, name: name, model: nil)
    }
    
    static func fromCD(element: SimulatedPeer) async throws -> SimulatedPeerRepresentation? {
        guard let url = element.url else { return nil }
        guard let name = element.name else { return nil }
        var model: SimulatedPeerModelRepresentation?
        
        if let mo = element.model {
            model = try await SimulatedPeerModelRepresentation.fromCD(element: mo)
        }
        
        return SimulatedPeerRepresentation(url: url, name: name, model: model)
    }
    
    
    
    func toCD() -> SimulatedPeer? {
        guard let url = self._url else { return nil }
        guard let name = self._name else { return nil }
        var sep: SimulatedPeer? = self.checkCoreData {element in element.url == self._url}
        
        if sep == nil {
            sep = SimulatedPeer(context: CoreDataController.instance.mainContext)
        }
        sep?.url = url
        sep?.name = name
        if let model = self._model, let model = model.toCDSimulatedPeerModel() {
            sep?.model = model
        }
        return sep
    }
    
}
