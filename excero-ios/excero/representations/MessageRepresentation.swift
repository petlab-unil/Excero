//
//  MessageRepresentation.swift
//  excero
//
//  Created by Alessandro on 19.02.24.
//

import Foundation

class MessageRepresentation: Representation {
    private var _url: String?
    private var _content: String?
    private var _authorUser: UserRepresentation?
    private var _authorSimulatedPeer: SimulatedPeerRepresentation?
    private var _conversation: ConversationRepresentation?
    
    public var url: String? {
        get {
            return self._url
        }
    }
    
    internal init(url: String? = nil, content: String? = nil, authorUser: UserRepresentation? = nil, authorSimulatedPeer: SimulatedPeerRepresentation? = nil, conversation: ConversationRepresentation? = nil) {
        self._url = url
        self._content = content
        self._authorUser = authorUser
        self._authorSimulatedPeer = authorSimulatedPeer
        self._conversation = conversation
    }
}

extension MessageRepresentation: AsyncCoreDataRepresentable {
    typealias CoreDataElement = Message
    typealias RepresentationElement = MessageRepresentation
    
    static func fromCD(element: Message) async throws -> MessageRepresentation? {
        guard let url = element.url else { return nil }
        guard let content = element.content else { return nil }
        guard let authorUser = element.authorUser else { return nil }
        guard let conversation = element.conversation else { return nil }
        
        var conversationRepresentation: ConversationRepresentation?
        var userRepresentation: UserRepresentation?
        var simulatedPeerRepresentation: SimulatedPeerRepresentation?
        
        if ConversationRepresentation.self is (any CodableRepresentable), let conversationUrl = conversation.url {
            conversationRepresentation = try await ConversationRepresentation.fromURL(url: conversationUrl)
        }
        
        if UserRepresentation.self is (any CodableRepresentable), let userURL = authorUser.url {
            userRepresentation = try await UserRepresentation.fromURL(url: userURL)
        }
        
        if SimulatedPeerRepresentation.self is (any CodableRepresentable), let sepUrl = element.authorSimulatedPeer?.url {
            simulatedPeerRepresentation = try await SimulatedPeerRepresentation.fromURL(url: sepUrl)
        }
        
        return MessageRepresentation(url: url, content: content, authorUser: userRepresentation, authorSimulatedPeer: simulatedPeerRepresentation, conversation: conversationRepresentation)
    }
    
    func toCD() -> Message? {
        guard let url = self._url else { return nil }
        guard let content = self._content else { return nil }
        guard let authorUser = self._authorUser else { return nil }
        guard let conversation = self._conversation else { return nil }
        
        var model: Message? = self.checkCoreData {element in element.url == self._url}
        if model == nil {
            model = Message(context: CoreDataController.instance.mainContext)
        }
        
        model?.content = content
        
        if ConversationRepresentation.self is (any CodableRepresentable) {
            model?.conversation = conversation.toCD()
        }
        
        if UserRepresentation.self is (any CodableRepresentable) {
            model?.authorUser = authorUser.toCD()
        }
        
        if SimulatedPeerRepresentation.self is (any CodableRepresentable), let sep = self._authorSimulatedPeer {
            model?.authorSimulatedPeer = sep.toCD()
        }
        
        return model
    }
}

extension MessageRepresentation: AsyncCodableRepresentable {
    typealias CodableElement = MessageCodable
    
    static func fromCodable(element: MessageCodable) async throws -> MessageRepresentation? {
        guard let authorUser = element.authorUser else { return nil }
        
        var userRepresentation: UserRepresentation?
        var sepRepresentation: SimulatedPeerRepresentation?
        var conversationRepresentation: ConversationRepresentation?
        
        userRepresentation = try await UserRepresentation.fromURL(url: authorUser)
        
        if let sepUrl = element.authorSEP {
            sepRepresentation = try await SimulatedPeerRepresentation.fromURL(url: sepUrl)
        }
        
        if let convUrl = element.conversation {
            conversationRepresentation = try await ConversationRepresentation.fromURL(url: convUrl)
        }
        
        return MessageRepresentation(url: element.url, content: element.content, authorUser: userRepresentation, authorSimulatedPeer: sepRepresentation, conversation: conversationRepresentation)
    }
    
    func toCodable() -> MessageCodable? {
        guard let content = self._content else { return nil }
        guard let conversation = self._conversation else { return nil }

        return MessageCodable(url: self._url, content: content, authorUser: self._authorUser?.url, authorSEP: self._authorSimulatedPeer?.url, conversation: conversation.url)
    }
    
    static func fromURL(url: String) async throws -> MessageRepresentation? {
        let decoder = JSONDecoder()
        let api = AuthenticatedApiFacade()
        let data = try await api.get(fullUrl: url, header: nil)
        if let data = data {
            let representation = try await MessageRepresentation.fromCodable(element: try decoder.decode(MessageCodable.self, from: data))
            return representation
        }
        return nil
    }
}

extension MessageRepresentation {
    func toFirebase() -> FirebaseMessage? {
     return nil
    }
    
    static func fromFirebase(element: FirebaseMessage, conversation: ConversationRepresentation?) -> MessageRepresentation? {
        var authUser: UserRepresentation?
        var authorSEP: SimulatedPeerRepresentation?
        
        if let user1 = conversation?.user1, user1.usernameHash == element.sender.senderId {
            authUser = user1
        }
        
        if let user2 = conversation?.user2, user2.usernameHash == element.sender.senderId {
            authUser = user2
        }
        
        if let sep = conversation?.simulatedPeer, sep.nameHash == element.sender.senderId {
            authorSEP = sep
        }
        
        return MessageRepresentation(url: nil, content: element.content, authorUser: authUser, authorSimulatedPeer: authorSEP, conversation: conversation)
    }
}
