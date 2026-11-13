//
//  ConversationController.swift
//  excero
//
//  Created by Alessandro on 06.05.24.
//

import Foundation
import AsyncPlus

class ConversationController {
    
    private let coreController: ModelController<Conversation>
    private let user: UserRepresentation
    private let resourceManager: ResourcesManager
    private let api: AuthenticatedApiFacade
    
    private let caching: Bool
    private var userPeer: UserRepresentation?
    private var sep: SimulatedPeerRepresentation?
    private var conversation: ConversationRepresentation?
    
    
    private static let CACHE_CONVERSATION_KEY: String = "ch.unil.excero.ConversationController.conversation"
    private static let CACHE_USER_PEER_KEY: String = "ch.unil.excero.ConversationController.userPeer"
    private static let CACHE_SEP_PEER_KEY: String = "ch.unil.excero.ConversationController.sepPeer"
    
    
    init(user: UserRepresentation, caching: Bool = true) {
        self.user = user
        self.coreController = ModelController<Conversation>()
        self.resourceManager = ResourcesManager.instance
        self.api = AuthenticatedApiFacade()
        self.caching = caching
    }
    
    func getConversation() async -> ConversationRepresentation? {
        if self.caching {
            if let cachedConv = ResourcesManager.instance.cache.object(forKey: ConversationController.CACHE_CONVERSATION_KEY as NSString) as? ConversationRepresentation {
                return cachedConv
            }
        }
        if self.resourceManager.networkAvailable {
            return await attempt {
                if let userURL = self.user.url {
                    return try await self.api.get(fullUrl: userURL  + "conversations/", header: nil)
                }
                return nil
            }.then { (data: Data?) -> ConversationRepresentation? in
                guard let data = data else { return nil }
                let decoder = JSONDecoder()
                do {
                    let conversation = try decoder.decode([ConversationCodable].self, from: data)
                    if let lastConv = conversation.last {
                        let conversation = try await ConversationRepresentation.fromCodable(element: lastConv)
                        if self.caching {
                            ResourcesManager.instance.cache.setObject(conversation as AnyObject, forKey: ConversationController.CACHE_CONVERSATION_KEY as NSString)
                        }
                        return conversation
                    }
                } catch {
                    ResourcesManager.logger.error("ConversationController.getConversation() Error while decoding user conversations. Detailed error: \(error)")
                }
                return nil
            }.asyncOptional() ?? nil
        } else {
            if let conversation = self.coreController.getLast() {
                do {
                    let conv = try await ConversationRepresentation.fromCD(element: conversation)
                    if self.caching {
                        ResourcesManager.instance.cache.setObject(conv as AnyObject, forKey: ConversationController.CACHE_CONVERSATION_KEY as NSString)
                    }
                    return conv
                } catch {
                    print("Error conversation could not be retrieved correctly from local DB: \(error)")
                }
            }
        }
        return nil
    }
    
    func getUserPeer() async -> UserRepresentation? {
        if self.caching {
            if let cached = ResourcesManager.instance.cache.object(forKey: ConversationController.CACHE_USER_PEER_KEY as NSString) as? UserRepresentation {
                return cached
            }
        }
        return await attempt {
            return await self.getConversation()
        }.then { (conversation: ConversationRepresentation?) -> UserRepresentation? in
            guard let conversation = conversation else { return nil }
            if let user1 = conversation.user1, let user2 = conversation.user2 {
                var peerUrl: String?
                if user1.url == self.user.url {
                    peerUrl = user2.url
                } else {
                    peerUrl = user1.url
                }
                if let peerUrl {
                    do {
                        let peerUser = try await UserRepresentation.fromURL(url: peerUrl, deep: false)
                        if self.caching {
                            ResourcesManager.instance.cache.setObject(peerUser as AnyObject, forKey: ConversationController.CACHE_USER_PEER_KEY as NSString)
                        }
                        return peerUser
                    } catch {
                        print(error)
                    }
                }
            }
            return nil
        }.asyncOptional() ?? nil
    }
    
    func getSEPPeer() async -> SimulatedPeerRepresentation? {
        if self.caching && self.sep != nil {
            if let cached = ResourcesManager.instance.cache.object(forKey: ConversationController.CACHE_SEP_PEER_KEY as NSString) as? SimulatedPeerRepresentation {
                return cached
            }
        }
        return await attempt {
            return await self.getConversation()
        }.then { (conversation: ConversationRepresentation?) -> SimulatedPeerRepresentation? in
            guard let conversation = conversation else { return nil }
            if let sep = conversation.simulatedPeer,
                conversation.user1 != nil || conversation.user2 != nil {
                if self.caching {
                    ResourcesManager.instance.cache.setObject(sep as AnyObject, forKey: ConversationController.CACHE_SEP_PEER_KEY as NSString)
                }
                return sep
            }
            return nil
        }.asyncOptional() ?? nil
    }
}
