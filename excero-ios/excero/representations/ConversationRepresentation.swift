//
//  ConversationRepresentation.swift
//  excero
//
//  Created by Alessandro on 19.02.24.
//

import Foundation

class ConversationRepresentation: Representation {
    private var _url: String?
    private var _documentPath: String?
    private var _user1: UserRepresentation?
    private var _user2: UserRepresentation?
    private var _simulatedPeer: SimulatedPeerRepresentation?
    private var _messages: [MessageRepresentation]?
    
    public var url: String? {
        get {
            return self._url
        }
    }
    
    public var documentPath: String? {
        get {
            return self._documentPath
        }
    }
    
    public var user1: UserRepresentation? {
        get {
            return self._user1
        }
    }
    
    public var user2: UserRepresentation? {
        get {
            return self._user2
        }
    }
    
    public var simulatedPeer: SimulatedPeerRepresentation? {
        get {
            return self._simulatedPeer
        }
    }
    
    public var messages: [MessageRepresentation]? {
        get {
            return self._messages
        }
    }
    
    internal init(url: String? = nil, documentPath: String? = nil, user1: UserRepresentation? = nil, user2: UserRepresentation? = nil, simulatedPeer: SimulatedPeerRepresentation? = nil, messages: Array<MessageRepresentation>? = nil) {
        self._url = url
        self._documentPath = documentPath
        self._user1 = user1
        self._user2 = user2
        self._simulatedPeer = simulatedPeer
        self._messages = messages
    }
}

extension ConversationRepresentation: AsyncCoreDataRepresentable {
    typealias CoreDataElement = Conversation
    typealias RepresentationElement = ConversationRepresentation
    
    static func fromCD(element: Conversation) async throws -> ConversationRepresentation? {
        guard let url = element.url else { return nil }
        guard let documentPath = element.documentPath else { return nil }
        
        var user1Representation: UserRepresentation?
        var user2Representation: UserRepresentation?
        var sepRepresentation: SimulatedPeerRepresentation?
        
        if let user1 = element.user1 {
            user1Representation = try await UserRepresentation.fromCD(element: user1)
        }
        
        if let user2 = element.user2 {
            user2Representation = try await UserRepresentation.fromCD(element: user2)
        }
        
        if let sep = element.simulatedPeer {
            sepRepresentation = try await SimulatedPeerRepresentation.fromCD(element: sep)
        }
        
        
        return ConversationRepresentation(url: url, documentPath: documentPath, user1: user1Representation, user2: user2Representation, simulatedPeer: sepRepresentation)
    }
    
    func toCD() -> Conversation? {
        guard let url = self._url else { return nil }
        guard let documentPath = self._documentPath else { return nil }
        
        var model: Conversation? = self.checkCoreData {element in element.url == self._url}
        if model == nil {
            model = Conversation(context: CoreDataController.instance.mainContext)
        }
        model?.url = url
        model?.documentPath = documentPath
        
        if let user1 = self._user1 {
            model?.user1 = user1.toCD()
        }
        
        if let user2 = self._user2 {
            model?.user2 = user2.toCD()
        }
        
        if let sep = self._simulatedPeer {
            model?.simulatedPeer = sep.toCD()
        }
        
        return model
    }
    
    
}

extension ConversationRepresentation: AsyncCodableRepresentable {
    typealias CodableElement = ConversationCodable
    
    static func fromCodable(element: ConversationCodable) -> ConversationRepresentation? {
        return ConversationRepresentation(url: element.url, documentPath: element.documentPath)
    }

    static func fromCodable(element: ConversationCodable) async throws -> ConversationRepresentation? {
        let user1 = try await UserRepresentation.fromURL(url: element.user1, deep: false)
        var user2: UserRepresentation?
        if let correspondingUser = element.user2 {
            user2 = try await UserRepresentation.fromURL(url: correspondingUser, deep: false)
        }
        
        var sep: SimulatedPeerRepresentation?
        if let correspondingSEP = element.simulatedPeer {
            sep = try await SimulatedPeerRepresentation.fromURL(url: correspondingSEP)
        }
        
        return ConversationRepresentation(url: element.url, documentPath: element.documentPath, user1: user1, user2: user2, simulatedPeer: sep)
    }
    
    func toCodable() -> ConversationCodable? {
        guard let user1URL = self._user1?.url else { return nil }
        var user2URL: String?
        var sepURL: String?
        
        if let u2 = self._user2 {
            user2URL = u2.url
        }
        
        if let sep = self._simulatedPeer {
            sepURL = sep.url
        }
        
        var messageURLs: Array<String> = []
        if let messages = self._messages {
            for message in messages {
                if let messageURL = message.url {
                    messageURLs.append(messageURL)
                }
            }
        }
        
        return ConversationCodable(url: self._url ?? "", documentPath: self._documentPath, user1: user1URL, user2: user2URL, simulatedPeer: sepURL, messages: nil)
    }
    
    static func fromURL(url: String) async throws -> ConversationRepresentation? {
        let decoder = JSONDecoder()
        let api = AuthenticatedApiFacade()
        let data = try await api.get(fullUrl: url, header: nil)
        if let data = data {
            let representation = try await ConversationRepresentation.fromCodable(element: try decoder.decode(ConversationCodable.self, from: data))
            return representation
        }
        return nil
    }
}
