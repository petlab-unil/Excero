//
//  AuthenticatedApiFacade+ApiFacade.swift
//  excero
//
//  Created by Alessandro Silacci on 20.04.23.
//

import Foundation
import UIKit
import AsyncPlus

class AuthenticatedApiFacade: Api {
    
    // -- MARK: CAN BE DELETED
    private var userInfoModelController = ModelController<UserInformation>()
    
    // -- MARK: CAN BE DELETED
    private var token: String? {
        get {
            guard let userInfo = ResourcesManager.instance.userInfo else {return nil}
            return userInfo.token
        }
    }

    private var refreshToken: String? {
        get {
            guard let userInfo = ResourcesManager.instance.userInfo else {return nil}
            return userInfo.refreshToken
        }
    }
    
    required init(url: String, header: Dictionary<String, String>) {
        super.init(url: url, header: header)
    }
    
    internal convenience init() {
        self.init(url: Constants.BASE_API_URL, header: [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ])
    }
    
    private func addToken(header: Dictionary<String, String>?, token: String) -> Dictionary<String, String> {
        var headers = Dictionary<String, String>()
        if let userHeaders = header {
            headers = userHeaders
        } else {
            headers = self.header
        }
        headers["Authorization"] = "Bearer " + token
        return headers
    }
    
    func refreshToken() async throws {
        let lastUserInfo = try await ResourcesManager.instance.getUserInfo().value
        guard let lastUserInfo = lastUserInfo else { throw AuthenticatedApiCallError.emptyUserInformation }
        var token: String?
        var refreshToken: String?
        let _ = lastUserInfo.managedObjectContext?.performAndWait {
            token = lastUserInfo.token
            refreshToken = lastUserInfo.refreshToken
        }
        guard let token = token else { throw AuthenticatedApiCallError.emptyToken }
        guard let refreshToken = refreshToken else { throw AuthenticatedApiCallError.emptyRefreshToken }
        
        let tokenCodable = Token(token: token, refreshToken: refreshToken)
        return try await attempt {
            let response = try await super.post(endpointPath: "token/refresh/", data: tokenCodable, header: nil)
            let decoder = JSONDecoder()
            guard let response else { throw AuthenticatedApiCallError.emptyToken }
            return try decoder.decode(Token.self, from: response)
        }.then { token in
            CoreDataController.instance.mainContext.perform {
                let userInfo = UserInformation(context: CoreDataController.instance.mainContext)
                userInfo.token = token.token
                if let refresh = token.refreshToken {
                    userInfo.refreshToken = refresh 
                } else {
                    userInfo.refreshToken = refreshToken
                }
                ResourcesManager.instance.userInfo = userInfo
                do {
                    try CoreDataController.instance.mainContext.save()
                } catch {
                    ResourcesManager.logger.error("AuthenticatedApiFacade.refreshToken could not save the new token. Detailed error: \(error)")
                }
            }
            ResourcesManager.instance.token = token
        }.asyncThrows()
    }
    
    override func prepareImagesForSend(files: Dictionary<String, UIImage>) -> Data {
        return Data()
    }
    
    func get(fullUrl: String, header: Dictionary<String, String>?) async throws -> Data? {
        guard let token = ResourcesManager.instance.token?.token else { throw AuthenticatedApiCallError.emptyToken }
        let headers = self.addToken(header: header, token: token)
        let fullUrl = fullUrl.replacingOccurrences(of: "http://", with: "https://")
        return try await attempt {
            return try await super.get(fullUrl: fullUrl, header: headers)
        }.recover { error in
            try await self.refreshToken()
            let headers = self.addToken(header: header, token: token)
            return try await super.get(fullUrl: fullUrl, header: headers)
        }.asyncThrows()
    }
    
    func get(endpointPath: String, header: Dictionary<String, String>?) async throws -> Data? {
        guard let token = ResourcesManager.instance.token?.token else { throw AuthenticatedApiCallError.emptyToken }
        let headers = self.addToken(header: header, token: token)
        return try await attempt {
            return try await super.get(endpointPath: endpointPath, header: headers)
        }.recover { error in
            try await self.refreshToken()
            return try await self.get(endpointPath: endpointPath, header: headers)
        }.asyncThrows()
    }
    
    func post(endpointPath: String, data: Codable, header: Dictionary<String, String>?) async throws -> Data? {
        guard let token = ResourcesManager.instance.token?.token else { throw AuthenticatedApiCallError.emptyToken }
        let headers = self.addToken(header: header, token: token)
        return try await attempt {
            return try await super.post(endpointPath: endpointPath, data: data, header: headers)
        }.recover { error in
            try await self.refreshToken()
            return try await self.post(endpointPath: endpointPath, data: data, header: headers)
        }.asyncThrows()
    }
    
    func post(endpointPath: String, data: Any, header: Dictionary<String, String>?) async throws -> Data? {
        guard let token = ResourcesManager.instance.token?.token else { throw AuthenticatedApiCallError.emptyToken }
        let headers = self.addToken(header: header, token: token)
        return try await attempt {
            return try await super.post(endpointPath: endpointPath, data: data, header: headers)
        }.recover { error in
            try await self.refreshToken()
            return try await self.post(endpointPath: endpointPath, data: data, header: headers)
        }.asyncThrows()
    }
    
    func post(fullUrl: String, data: Codable, header: Dictionary<String, String>?) async throws -> Data? {
        guard let token = ResourcesManager.instance.token?.token else { throw AuthenticatedApiCallError.emptyToken }
        let headers = self.addToken(header: header, token: token)
        let fullUrl = fullUrl.replacingOccurrences(of: "http://", with: "https://")
        return try await attempt {
            return try await super.post(fullUrl: fullUrl, data: data, header: headers)
        }.recover { error in
            try await self.refreshToken()
            return try await self.post(fullUrl: fullUrl, data: data, header: headers)
        }.asyncThrows()
    }
    
    func post(fullUrl: String, data: [StepRecordCodable], header: Dictionary<String, String>?, delegate: URLSessionTaskDelegate?) async throws -> URLSessionUploadTask? {
        guard let token = ResourcesManager.instance.token?.token else { throw AuthenticatedApiCallError.emptyToken }
        guard let url = URL(string: fullUrl.replacingOccurrences(of: "http://", with: "https://")) else { return nil }
        let headers = self.addToken(header: header, token: token)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        let jsonEncoder = JSONEncoder()
        let jsonData = try jsonEncoder.encode(data)
        
        let tempDir = FileManager.default.temporaryDirectory
        let localURL = tempDir.appendingPathComponent("useless")
        try? jsonData.write(to: localURL)
        
        var bgUrlSession: URLSession = {
            let config = URLSessionConfiguration.background(withIdentifier: Constants.URLSESSION_BG_IDENTIFIER)
            config.isDiscretionary = false
            config.sessionSendsLaunchEvents = true
            return URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        }()
        return bgUrlSession.uploadTask(with: request, fromFile: localURL)
    }
    
    func postFormData(endpointPath: String, file: Data, additionalData: Dictionary<String, String>? = nil, header: Dictionary<String, String>?) async throws -> Data? {
        guard let token = ResourcesManager.instance.token?.token else { throw AuthenticatedApiCallError.emptyToken }
        let headers = self.addToken(header: header, token: token)
        return try await attempt {
            return try await super.postFormData(endpointPath: endpointPath, file: file, additionalData: additionalData, header: headers)
        }.recover { error in
            try await self.refreshToken()
            return try await self.postFormData(endpointPath: endpointPath, file: file, additionalData: additionalData, header: headers)
        }.asyncThrows()
    }
    
    func postFormData(fullUrl: String, file: Data, additionalData: Dictionary<String,String>? = nil, header: Dictionary<String, String>?) async throws -> Data? {
        guard let token = ResourcesManager.instance.token?.token else { throw AuthenticatedApiCallError.emptyToken }
        let headers = self.addToken(header: header, token: token)
        let fullUrl = fullUrl.replacingOccurrences(of: "http://", with: "https://")
        return try await attempt {
            return try await super.postFormData(fullUrl: fullUrl, file: file, header: headers)
        }.recover { error in
            try await self.refreshToken()
            return try await self.postFormData(fullUrl: fullUrl, file: file, header: headers)
        }.asyncThrows()
    }
    
    func put(fullUrl: String, data: Codable, header: Dictionary<String, String>?) async throws -> Data? {
        guard let token = ResourcesManager.instance.token?.token else { throw AuthenticatedApiCallError.emptyToken }
        let headers = self.addToken(header: header, token: token)
        let fullUrl = fullUrl.replacingOccurrences(of: "http://", with: "https://")
        return try await attempt {
            return try await super.put(fullUrl: fullUrl, data: data, header: headers)
        }.recover { error in
            try await self.refreshToken()
            return try await self.put(fullUrl: fullUrl, data: data, header: headers)
        }.asyncThrows()
    }
    
    // -- MARK: Deprecated
    func delete(endpointPath: String, data: Any, header: Dictionary<String, String>?, handler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) async throws {
        guard let token = ResourcesManager.instance.token?.token else { throw AuthenticatedApiCallError.emptyToken }
        let headers = self.addToken(header: header, token: token)
        await super.delete(endpointPath: endpointPath, data: data, header: headers) { data, response, error in
            Task {
                try await self.refreshToken()
            }
            handler(data, response, error)
        }
    }
    
    // -- MARK: Deprecated
    func put(endpointPath: String, data: Any, header: Dictionary<String, String>?, handler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) async throws {
        guard let token = ResourcesManager.instance.token?.token else { throw AuthenticatedApiCallError.emptyToken }
        let headers = self.addToken(header: header, token: token)
        await super.put(endpointPath: endpointPath, data: data, header: headers) { data, response, error in
            Task {
                try await self.refreshToken()
            }
            handler(data, response, error)
        }
    }
    
    // -- MARK: Deprecated
    func get(endpointPath: String, header: Dictionary<String, String>?, handler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) async throws {
        guard let token = ResourcesManager.instance.token?.token else { throw AuthenticatedApiCallError.emptyToken }
        let headers = self.addToken(header: header, token: token)
        await super.get(endpointPath: endpointPath, header: headers) { data, response, error in
            Task {
                try await self.refreshToken()
            }
            handler(data, response, error)
        }
    }
    
    // -- MARK: Deprecated
    func post(endpointPath: String, data: Any, header: Dictionary<String, String>?, handler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) async throws {
        guard let token = ResourcesManager.instance.token?.token else { throw AuthenticatedApiCallError.emptyToken }
        let headers = self.addToken(header: header, token: token)
        await super.post(endpointPath: endpointPath, data: data, header: headers) { data, response, error in
            Task {
                try await self.refreshToken()
            }
            handler(data, response, error)
        }
    }
}
