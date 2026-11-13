//
//  AuthenticationController.swift
//  excero
//  THIS IS JUST A TEST
//  Created by Alessandro on 20.08.24.
//

import Foundation
import AuthenticationServices
import Security
import LocalAuthentication


struct Credentials {
    var username: String
    var password: String
}

enum KeychainError: Error {
    case noPassword
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
}

class AuthenticationController: NSObject {
    
    private let relyingPartyIdentifier: String?
    private let context: LAContext
    
    init(relyingPartyIdentifier: String? = nil) {
        self.relyingPartyIdentifier = relyingPartyIdentifier
        self.context = LAContext()
        self.context.localizedReason = "Access your password on the keychain"
        self.context.touchIDAuthenticationAllowableReuseDuration = 10
    }
    
    public func registerPasskeyApp(challenge: Data, username: String, userID: Data, anchorProvider: ASAuthorizationControllerPresentationContextProviding) {
        guard let relyingPartyIdentifier = self.relyingPartyIdentifier else { return }
        let platformProvider  = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: relyingPartyIdentifier)
        let platformKeyRequest = platformProvider.createCredentialRegistrationRequest(challenge: challenge, name: username, userID: userID)
        let authController = ASAuthorizationController(authorizationRequests: [platformKeyRequest])
        authController.delegate = self
        authController.presentationContextProvider = anchorProvider
        authController.performRequests()
    }
    
    public func saveCredentials(username: String, password: String) throws {
        
        let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .userPresence, nil)
        guard let pwd = password.data(using: .utf8) else { return }
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrLabel as String: "Excero",
            kSecAttrAccount as String: username,
            kSecValueData as String: pwd,
            kSecAttrAccessControl as String: access as Any,
            kSecUseAuthenticationContext as String: self.context,
        ]
        
        let lookUpQuery: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrLabel as String: "Excero",
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecUseAuthenticationContext as String: self.context,
            kSecReturnData as String: true,
        ]
        
        var item: CFTypeRef?
        let checkExistingStatus = SecItemCopyMatching(lookUpQuery as CFDictionary, &item)
        if checkExistingStatus != errSecItemNotFound {
            try self.deleteCredentials()
        }
        
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
    }
    
    public func getCredentials() throws -> Credentials {

        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrLabel as String: "Excero",
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecUseAuthenticationContext as String: self.context,
            kSecReturnData as String: true,
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else { throw KeychainError.noPassword }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
        
        guard let existingItem = item as? [String : Any],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let password = String(data: passwordData, encoding: String.Encoding.utf8),
            let username = existingItem[kSecAttrAccount as String] as? String
        else {
            throw KeychainError.unexpectedPasswordData
        }
        return Credentials(username: username, password: password)
    }
    
    public func updateCredentials(username: String?, password: String?) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrLabel as String: "Excero",
        ]
        var updateQuery: [String: Any] = [:]
        if let username {
            updateQuery[kSecAttrAccount as String] = username
        }
        if let password {
            updateQuery[kSecValueData as String] = password
        }
        
        let status = SecItemUpdate(query as CFDictionary, updateQuery as CFDictionary)
        guard status != errSecItemNotFound else { throw KeychainError.noPassword }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
    }
    
    public func deleteCredentials() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrLabel as String: "Excero",
            kSecUseAuthenticationContext as String: self.context,
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }
    }
    
    public func activate(pwd1: String, pwd2: String, token: String) async throws -> Data? {
        let authApi = AuthenticatedApiFacade()
        return try await authApi.activate(pwd1: pwd1, pwd2: pwd2, token: token)
    }
}

extension AuthenticationController: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
            print("New Authentication is registered")
        } else if let credential = authorization.credential as? ASAuthorizationPublicKeyCredentialAssertion {
            print("New Authentication needs to be verified")
        } else {
            print("Authentication was neither registered or verified")
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Error while authenticating user.")
    }
    
    
}
