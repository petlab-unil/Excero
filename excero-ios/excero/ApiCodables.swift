//
//  ApiCodables.swift
//  excero
//
//  Created by Alessandro Silacci on 21.04.23.
//

import Foundation

struct Token: Codable {
    let token: String?
    let refreshToken: String?
    
    enum CodingKeys: CodingKey {
        case token, refreshToken
        
        var stringValue: String {
            switch self {
                case .token: return "access"
                case .refreshToken: return "refresh"
            }
        }
    }
}

struct ActivationUserCodable: Codable {
    let username: String?
    
    enum CodingKeys: CodingKey {
        case username
        
        var stringValue: String {
            switch self {
                case .username: return "u"
            }
        }
    }
}

struct AvatarPieceCodable: Codable {
    let url: String
    let name: String
    let width: Double
    let height: Double
    let positionX: Double
    let positionY: Double
    let positionZ: Double
    let file: String
    
    enum CodingKeys: CodingKey {
        case url, name, width, height, positionX, positionY, positionZ, file
        var stringValue: String {
            switch self {
            case .url: return "url"
            case .name: return "name"
            case .width: return "width"
            case .height: return "height"
            case .positionX: return "position_x"
            case .positionY: return "position_y"
            case .positionZ: return "position_z"
            case .file: return "file"
            }
        }
    }
}

struct AvatarTypeCodable: Codable {
    let url: String
    let typeName: String
    let avatarPiecesUrls: [String]?
    
    enum CodingKeys: CodingKey {
        case url, typeName, avatarPiecesUrls
        var stringValue: String {
            switch self {
            case .url: return "url"
            case .typeName: return "type_name"
            case .avatarPiecesUrls: return "avatarpieces"
            }
        }
    }
}

struct AvatarCodable: Codable {
    let url: String
    let tint: String
    let base: String
    let head: String
    let torso: String
    let legs: String
    let shoes: String
    let type: String
    
    
    enum CodingKeys: CodingKey {
        case url, tint, base, head, torso, legs, shoes, type
        var stringValue: String {
            switch self {
            case .url: return "url"
            case .tint: return "tint"
            case .base: return "base"
            case .head: return "head"
            case .torso: return "torso"
            case .legs: return "legs"
            case .shoes: return "shoes"
            case .type: return "type"
            }
        }
    }
}

struct MessageCodable: Codable {
    let url: String?
    let content: String
    let authorUser: String?
    let authorSEP: String?
    let conversation: String?
    
    enum CodingKeys: CodingKey {
        case url, content, authorUser, authorSEP, conversation
        var stringValue: String {
            switch self {
            case .url: return "url"
            case .content: return "content"
            case .authorUser: return "author_user"
            case .authorSEP: return "author_simulated_peer"
            case .conversation: return "conversation"
            }
        }
    }
}

struct ConversationCodable: Codable {
    let url: String
    let documentPath: String?
    let user1: String
    let user2: String?
    let simulatedPeer: String?
    let messages: Array<String>?
    
    enum CodingKeys: CodingKey {
        case url, documentPath, user1, user2, simulatedPeer, messages
        var stringValue: String {
            switch self {
            case .url: return "url"
            case .documentPath: return "document_path"
            case .user1: return "user1"
            case .user2: return "user2"
            case .simulatedPeer: return "simulated_peer"
            case .messages: return "messages"
            }
        }
    }
}

struct FirebaseTokenCodable: Codable {
    let token: String
    
    enum CodingKeys: CodingKey {
        case token
        var stringValue: String {
            switch self {
            case .token: return "token"
            }
        }
    }
}

struct SimulatedPeerModelCodable: Codable {
    let url: String
    let preview: String
    let avatar: String
    
    enum CodingKeys: CodingKey {
        case url, preview, avatar
        var stringValue: String {
            switch self {
            case .url: return "url"
            case .preview: return "preview"
            case .avatar: return "avatar"
            }
        }
    }
}

struct SimulatedPeerCodable: Codable {
    let url: String
    let name: String
    let model: String?
    
    enum CodingKeys: CodingKey {
        case url, name, model
        var stringValue: String {
            switch self {
            case .url: return "url"
            case .name: return "name"
            case .model: return "simulated_peer_model"
            }
        }
    }
}

struct UserCodable: Codable {
    let url: String
    let username: String
    let expCondition: String?
    let simulatedPeer: String?
    let avatar: String?
    let stepRecords: [String]?
    let fcmToken: String?
    
    enum CodingKeys: CodingKey {
        case url, username, expCondition, simulatedPeer, avatar, stepRecords, fcmToken
        var stringValue: String {
            switch self {
            case .url: return "url"
            case .username: return "username"
            case .expCondition: return "experimental_condition"
            case .simulatedPeer: return "simulated_peer"
            case .avatar: return "avatar"
            case .stepRecords: return "step_records"
            case .fcmToken: return "fcm_token"
            }
        }
    }
}

struct ExperimentalConditionCodable: Codable {
    let url: String
    let acronym: String
    let name: String
    let start: Date
    let end: Date
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(start.ISO8601Format(), forKey: .start)
        try? container.encode(end.ISO8601Format(), forKey: .end)
        try? container.encode(url, forKey: .url)
        try? container.encode(acronym, forKey: .acronym)
        try? container.encode(name, forKey: .name)
    }
    
    enum CodingKeys: CodingKey {
        case url, acronym, name, start, end
        var stringValue: String {
            switch self {
            case .url: return "url"
            case .acronym: return "acronym"
            case .name: return "name"
            case .start: return "start"
            case .end: return "end"
            }
        }
    }
}

struct StepRecordCodable: Codable {
    let url: String
    let value: Int32
    let start: Date
    let end: Date

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(start.ISO8601Format(), forKey: .start)
        try? container.encode(end.ISO8601Format(), forKey: .end)
        try? container.encode(value, forKey: .value)
        try? container.encode(url, forKey: .url)
    }
        
    enum CodingKeys: CodingKey {
        case url, value, start, end
        var stringValue: String {
            switch self {
            case .url: return "url"
            case .value: return "count"
            case .start: return "start"
            case .end: return "end"
            }
        }
    }
}

struct InterventionWeekCodable: Codable {
    let url: String
    let begin: Date
    let end: Date
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(begin.ISO8601Format(), forKey: .begin)
        try? container.encode(end.ISO8601Format(), forKey: .end)
        try? container.encode(url, forKey: .url)
    }
        
    enum CodingKeys: CodingKey {
        case url, begin, end
        var stringValue: String {
            switch self {
            case .url: return "url"
            case .begin: return "begin"
            case .end: return "end"
            }
        }
    }
}

struct GoalCodable: Codable {
    let url: String
    let start: Date
    let end: Date
    let value: Int
    let attained: Bool
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(start.ISO8601Format(), forKey: .start)
        try? container.encode(end.ISO8601Format(), forKey: .end)
        try? container.encode(url, forKey: .url)
        try? container.encode(value, forKey: .value)
        try? container.encode(attained, forKey: .attained)
    }
        
    enum CodingKeys: CodingKey {
        case url, start, end, value, attained
        var stringValue: String {
            switch self {
            case .url: return "url"
            case .start: return "start"
            case .end: return "end"
            case .value: return "value"
            case .attained: return "attained"
            }
        }
    }
}

struct UserReportCodable: Codable {
    let issuer: String
    let reportedUser: String
    let issue: String
    
    enum CodingKeys: CodingKey {
        case issuer, reportedUser, issue
        var stringValue: String {
            switch self {
            case .issuer: return "issuer"
            case .reportedUser: return "reported_user"
            case .issue: return "issue"
            }
        }
    }
}

struct AnalyticRecordCodable: Codable { 
    let actionName: String
    let target: String
    let appVersion: String
    
    enum CodingKeys: CodingKey {
        case actionName, target, appVersion
        var stringValue: String {
            switch self {
            case .actionName: return "action_name"
            case .target: return "target"
            case .appVersion: return "app_version"
            }
        }
    }
}
