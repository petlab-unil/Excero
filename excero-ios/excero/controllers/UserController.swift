//
//  UserController.swift
//  excero
//
//  Created by Alessandro on 27.08.24.
//

import Foundation

class UserController {
    private var currentUser: UserRepresentation?
    private var api: AuthenticatedApiFacade
    
    init(user: UserRepresentation? = nil) {
        if let user  {
            self.currentUser = user
        } else {
            self.currentUser = ResourcesManager.instance.user
        }
        self.api = AuthenticatedApiFacade()
    }
    
    
    public func deactivate(userDefaultsSuitesName: String = Constants.USER_DEFAULTS_SUITE_NAME) async throws {
        if let userDefaults = UserDefaults(suiteName: userDefaultsSuitesName) {
            userDefaults.set(true, forKey: Constants.USER_DEFAULTS_ACCOUNT_DEACTIVATED)
        }
        let _ = try await api.get(fullUrl: Constants.BASE_API_URL + "users/deactivate/", header: nil)
    }
    
}
