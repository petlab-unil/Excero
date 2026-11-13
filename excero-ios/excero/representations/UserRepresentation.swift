//
//  UserRepresentation.swift
//  excero
//
//  Created by Alessandro on 03.10.23.
//

import Foundation
import CryptoKit

class UserRepresentation: Representation {
    private var _url: String?
    private var _experimentalConditions: ExperimentalConditionRepresentation?
    private var _username: String?
    private var _simulatedPeer: SimulatedPeerRepresentation?
    private var _avatar: AvatarRepresentation?
    private var _stepRecords: [StepRecordRepresentation]?
    private var _fcmToken: String?
    private var _avatarUrl: String?
    
    public var url: String? {
        get {
            return self._url
        }
    }
    
    public var experimentalConditions: ExperimentalConditionRepresentation? {
        get {
            return self._experimentalConditions
        }
    }
    
    public var username: String? {
        get {
            return self._username
        }
    }
    
    public var lastExperimentalCondition: ExperimentalConditionRepresentation? {
        get {
            if let conditions = self._experimentalConditions {
                return conditions
            } else {
                return nil
            }
        }
    }
    
    public var simulatedPeer: SimulatedPeerRepresentation? {
        get {
            return self._simulatedPeer
        }
    }
    
    public var avatar: AvatarRepresentation? {
        get async throws {
            if let avatar = self._avatar {
                return avatar
            } else if let avatarUrl = self._avatarUrl {
                self._avatar = try await AvatarRepresentation.fromURL(url: avatarUrl)
                return self._avatar
            }
            return nil
        }
    }
    
    public var usernameHash: String? {
        get {
            if let username = self._username {
                return SHA256.hash(data: Data(username.utf8)).compactMap { String(format: "%02x", $0) }.joined()
            }
            return nil
        }
    }
    
    public var fcmToken: String? {
        get {
            return self._fcmToken
        }
        set {
            self._fcmToken = newValue
        }
    }
    
    internal init(url: String, experimentalConditions: ExperimentalConditionRepresentation?, username: String, simulatedPeer: SimulatedPeerRepresentation?, avatar: AvatarRepresentation?, stepRecords: [StepRecordRepresentation]) {
        self._url = url
        self._experimentalConditions = experimentalConditions
        self._username = username
        self._simulatedPeer = simulatedPeer
        self._avatar = avatar
        self._stepRecords = stepRecords
    }
    
    internal init(url: String, experimentalConditions: String?, username: String, simulatedPeer: String?, avatar: String?, stepRecords: [String]?) {
        self._url = url
        //self._experimentalConditions = experimentalConditions
        self._username = username
        //self._simulatedPeer = simulatedPeer
        self._avatarUrl = avatar
        //self._stepRecords = stepRecords
    }
}

extension UserRepresentation {
    func toCDUser() -> User? {
        guard let url = self._url else { return nil }
        guard let expConds = self._experimentalConditions else { return nil }
        guard let username = self._username else { return nil }
        guard let avatar = self._avatar?.toCDAvatar(isSelf: true) else { return nil }
        guard let steps = self._stepRecords else { return nil }
                
        var expCond: ExperimentalCondition?
        if let ec = expConds.toCDExperimentalCondition() {
            expCond = ec
        }
        
        var cdSteps: [StepArchive] = []
        for s in steps {
            if let s = s.toCDStepRecord() {
                cdSteps.append(s)
            }
        }
        
        let user = User(context: CoreDataController.instance.mainContext)
        user.url = url
        user.username = username
        user.experimentalConditions = expCond
        user.avatar = avatar
        user.stepRecords = NSSet(array: cdSteps)
        
        if let sep = self._simulatedPeer?.toCD() {
            user.simulatedPeer = sep
        }
        
        return user
    }
    
    static func fromCDUser(user: User) async throws -> UserRepresentation? {
        var steps: [StepRecordRepresentation] = []
        var expConds: ExperimentalConditionRepresentation?
        var simulatedPeer: SimulatedPeerRepresentation?
        let url = user.managedObjectContext?.performAndWait {
            return user.url
        }
        guard let url else { return nil }
        let username = user.managedObjectContext?.performAndWait {
            return user.username
        }
        guard let username else { return nil }
        let avatar = user.managedObjectContext?.performAndWait {
            return user.avatar
        }
        guard let avatar, let avatar = try await AvatarRepresentation.fromCDAvatar(avatar) else { return nil }
        
        if let stepRecords = user.stepRecords {
            for step in stepRecords.allObjects {
                if let s = StepRecordRepresentation.fromCDStepRecord(step: step as! StepArchive) {
                    steps.append(s)
                }
            }
        }
        
        if let expConditions = user.experimentalConditions {
            if let e = ExperimentalConditionRepresentation.fromCDExperimentalCondition(expCond: expConditions) {
                expConds = e
            }
        }
        
        // TODO: Add check for sep in cd
        
        return UserRepresentation(url: url, experimentalConditions: expConds,
                                  username: username, simulatedPeer: simulatedPeer,
                                  avatar: avatar, stepRecords: steps)
    }
}

extension UserRepresentation {
    func toCodable() -> UserCodable? {
        var avatarUrl: String = ""
        var sepUrl: String = ""
        var expConds: String = ""
        var steps: [String] = []
        var fcmToken: String?
        
        if let avatar = self._avatar, let avatar = avatar.toCodable() {
            avatarUrl = avatar.url
        }
        if let sep = self._simulatedPeer, let sep = sep.toCodable() {
            sepUrl = sep.url
        }
        if let expCds = self._experimentalConditions {
            expConds = expCds.url ?? ""
        }
        if let fcm = self._fcmToken {
            fcmToken = fcm
        }
        /*if let steps = self._steps, let steps = self._steps {
            steps = "" // FIXME: change this when steps are implemented
        }*/
        guard let url = self._url else { return nil }
        guard let username = self._username else { return nil }
        
        
        return UserCodable(url: url, username: username, expCondition: expConds, simulatedPeer: sepUrl, avatar: avatarUrl, stepRecords: steps, fcmToken: fcmToken ?? "")
    }
    
    static func fromCodable(user: UserCodable) async throws -> UserRepresentation? {
        var avatarRepresentation: AvatarRepresentation?
        var sep: SimulatedPeerRepresentation?
        var expConditions: ExperimentalConditionRepresentation?
        var steps: [StepRecordRepresentation] = []
        
        if let avatar = user.avatar {
            avatarRepresentation = try await AvatarRepresentation.fromURL(url: avatar.replacingOccurrences(of: "http://", with: "https://"))
        }
        
        if let expCondUrl = user.expCondition {
            if let expCond = try await ExperimentalConditionRepresentation.fromURL(url: expCondUrl.replacingOccurrences(of: "http://", with: "https://")) {
                expConditions = expCond
            }
        }
        
        if let stepRecords = user.stepRecords {
            for sr in stepRecords {
                if let s = try await StepRecordRepresentation.fromURL(url: sr.replacingOccurrences(of: "http://", with: "https://")) {
                    steps.append(s)
                }
            }
        }
        
        if let simPeer = user.simulatedPeer {
            sep = try await SimulatedPeerRepresentation.fromURL(url: simPeer.replacingOccurrences(of: "http://", with: "https://"))
        }
        
        return UserRepresentation(url: user.url, experimentalConditions: expConditions,
                                  username: user.username, simulatedPeer:
                                    sep, avatar: avatarRepresentation, stepRecords: steps)
    }
}

extension UserRepresentation: AsyncCoreDataRepresentable {
    typealias CoreDataElement = User
    typealias RepresentationElement = UserRepresentation
    
    static func fromCD(element: User) async throws -> UserRepresentation? {
        var steps: [StepRecordRepresentation] = []
        var expConds: ExperimentalConditionRepresentation?
        var simulatedPeer: SimulatedPeerRepresentation?
        
        guard let url = element.url else { return nil }
        guard let username = element.username else { return nil }
        guard let avatar = element.avatar, let avatar = try await AvatarRepresentation.fromCDAvatar(avatar) else { return nil }
        
        /*if let stepRecords = element.stepRecords {
            for step in stepRecords.allObjects {
                if let s = StepRecordRepresentation.fromCDStepRecord(step: step as! StepArchive) {
                    steps.append(s)
                }
            }
        }*/
        
        if let expConditions = element.experimentalConditions {
            if let e = ExperimentalConditionRepresentation.fromCDExperimentalCondition(expCond: expConditions) {
                expConds = e
            }
        }
        
        // TODO: Add check for sep in cd
        
        return UserRepresentation(url: url, experimentalConditions: expConds,
                                  username: username, simulatedPeer: simulatedPeer,
                                  avatar: avatar, stepRecords: steps)
    }
    
    func toCD() -> User? {
        guard let url = self._url else { return nil }
        guard let expConds = self._experimentalConditions else { return nil }
        guard let username = self._username else { return nil }
        guard let avatar = self._avatar?.toCDAvatar(isSelf: true) else { return nil }
        guard let steps = self._stepRecords else { return nil }
                
        var expCond: ExperimentalCondition?
        if let ec = expConds.toCDExperimentalCondition() {
            expCond = ec
        }
        
        var cdSteps: [StepArchive] = []
        for s in steps {
            if let s = s.toCDStepRecord() {
                cdSteps.append(s)
            }
        }
        
        var user: User? = self.checkCoreData {element in element.url == self._url}
        
        if user == nil {
           user = User(context: CoreDataController.instance.mainContext)
        }
        user?.url = url
        user?.username = username
        user?.experimentalConditions = expCond
        user?.avatar = avatar
        user?.stepRecords = NSSet(array: cdSteps)
        
        if let sep = self._simulatedPeer?.toCD() {
            user?.simulatedPeer = sep
        }
        
        return user
    }
    
}

extension UserRepresentation: AsyncCodableRepresentable {
    typealias CodableElement = UserCodable
    
    static func fromCodable(element: UserCodable) async throws -> UserRepresentation? {
        var avatarRepresentation: AvatarRepresentation?
        var sep: SimulatedPeerRepresentation?
        var expConditions: ExperimentalConditionRepresentation?
        var steps: [StepRecordRepresentation] = []
        
        if let avatar = element.avatar {
            avatarRepresentation = try await AvatarRepresentation.fromURL(url: avatar.replacingOccurrences(of: "http://", with: "https://"))
        }
        
        if let expCondUrl = element.expCondition {
            if let expCond = try await ExperimentalConditionRepresentation.fromURL(url: expCondUrl.replacingOccurrences(of: "http://", with: "https://")) {
                expConditions = expCond
            }
        }
        
        if let stepRecords = element.stepRecords {
            for sr in stepRecords {
                if let s = try await StepRecordRepresentation.fromURL(url: sr.replacingOccurrences(of: "http://", with: "https://")) {
                    steps.append(s)
                }
            }
        }
        
        if let simPeer = element.simulatedPeer {
            sep = try await SimulatedPeerRepresentation.fromURL(url: simPeer.replacingOccurrences(of: "http://", with: "https://"))
        }
        
        return UserRepresentation(url: element.url, experimentalConditions: expConditions,
                                  username: element.username, simulatedPeer:
                                    sep, avatar: avatarRepresentation, stepRecords: steps)
    }
    
    static func fromCodable(element: UserCodable, deep: Bool = true) async throws -> UserRepresentation? {
        var avatarRepresentation: AvatarRepresentation?
        var sep: SimulatedPeerRepresentation?
        var expConditions: ExperimentalConditionRepresentation?
        var steps: [StepRecordRepresentation] = []
                
        if deep {
            if let avatar = element.avatar {
                avatarRepresentation = try await AvatarRepresentation.fromURL(url: avatar.replacingOccurrences(of: "http://", with: "https://"))
            }
            
            if let expCondUrl = element.expCondition {
                if let expCond = try await ExperimentalConditionRepresentation.fromURL(url: expCondUrl.replacingOccurrences(of: "http://", with: "https://")) {
                    expConditions = expCond
                }
            }
            
            if let stepRecords = element.stepRecords {
                for sr in stepRecords {
                    if let s = try await StepRecordRepresentation.fromURL(url: sr.replacingOccurrences(of: "http://", with: "https://")) {
                        steps.append(s)
                    }
                }
            }
            
            if let simPeer = element.simulatedPeer {
                sep = try await SimulatedPeerRepresentation.fromURL(url: simPeer.replacingOccurrences(of: "http://", with: "https://"))
            }
            return UserRepresentation(url: element.url, experimentalConditions: expConditions,
                                      username: element.username, simulatedPeer:
                                        sep, avatar: avatarRepresentation, stepRecords: steps)
        }
        
        return UserRepresentation(url: element.url, experimentalConditions: element.expCondition, username: element.username, simulatedPeer: element.simulatedPeer, avatar: element.avatar, stepRecords: element.stepRecords)
    }
    
    func toCodable(element: UserRepresentation) -> UserCodable? {
        var avatarUrl: String = ""
        var sepUrl: String = ""
        var expConds: String = ""
        var steps: [String] = []
        var fcmToken: String?
        
        if let avatar = self._avatar, let avatar = avatar.toCodable() {
            avatarUrl = avatar.url
        }
        if let sep = self._simulatedPeer, let sep = sep.toCodable() {
            sepUrl = sep.url
        }
        if let expCds = self._experimentalConditions {
            expConds = expCds.url ?? ""
        }
        if let token = self._fcmToken {
            fcmToken = token
        }
        /*if let steps = self._steps, let steps = self._steps {
            steps = "" // FIXME: change this when steps are implemented
        }*/
        guard let url = self._url else { return nil }
        guard let username = self._username else { return nil }
        
        
        return UserCodable(url: url, username: username, expCondition: expConds, simulatedPeer: sepUrl, avatar: avatarUrl, stepRecords: steps, fcmToken: fcmToken ?? "")
    }
    
    static func fromURL(url: String) async throws -> UserRepresentation? {
        let decoder = JSONDecoder()
        let api = AuthenticatedApiFacade()
        let data = try await api.get(fullUrl: url, header: nil)
        if let data = data {
            let representation = try await UserRepresentation.fromCodable(element: try decoder.decode(UserCodable.self, from: data))
            return representation
        }
        return nil
    }
    
    static func fromURL(url: String, deep: Bool = true) async throws -> UserRepresentation? {
        let decoder = JSONDecoder()
        let api = AuthenticatedApiFacade()
        let data = try await api.get(fullUrl: url, header: nil)
        if let data = data {
            let representation = try await UserRepresentation.fromCodable(element: try decoder.decode(UserCodable.self, from: data), deep: deep)
            return representation
        }
        return nil
    }
}


