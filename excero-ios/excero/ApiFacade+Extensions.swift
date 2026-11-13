//
//  ApiAuthentication+ApiFacade.swift
//  excero
//
//  Created by Alessandro Silacci on 23.03.23.
//

import Foundation

extension ApiFacade {
    
    
    func authenticate(username: String, password: String, handler: @escaping (Data?) -> Void) async {
        let url = Constants.BASE_API_URL
        let header = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        await self.post(fullUrl: url + "token/", data: ["email":username, "password":password],
                        header: header) { data, response, error in
            if let _ = error {
                handler(nil)
            }
            if let resBody = data {
                let decoder = JSONDecoder()
                let userInfo = UserInformation(context: CoreDataController.instance.mainContext)
                userInfo.email = username
                userInfo.password = password
                let response = try? decoder.decode(Token.self, from: resBody)
                userInfo.token = response?.token
                userInfo.refreshToken = response?.refreshToken
                ResourcesManager.instance.token = Token(token: response?.token, refreshToken: response?.refreshToken)
                do {
                    try CoreDataController.instance.mainContext.save()
                } catch {
                    print("error")
                }
                handler(resBody)
            }
            handler(nil)
        }
    }
    
    func authenticate(username: String, password: String) async -> UserInformation? {
        let url = Constants.BASE_API_URL
        let header = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        do {
            let connection = try await self.post(fullUrl: url + "token/", data: ["username":username, "password":password], header: header)
            if let resBody = connection {
                let decoder = JSONDecoder()
                var userInfo: UserInformation?
                let response = try? decoder.decode(Token.self, from: resBody)
                CoreDataController.instance.mainContext.performAndWait {
                    userInfo = UserInformation(context: CoreDataController.instance.mainContext)
                    userInfo?.email = username
                    userInfo?.password = password
                    userInfo?.token = response?.token
                    userInfo?.refreshToken = response?.refreshToken
                    do {
                        try CoreDataController.instance.mainContext.save()
                    } catch {
                        print("error")
                    }
                }
                
                ResourcesManager.instance.token = Token(token: response?.token, refreshToken: response?.refreshToken)
                
                return userInfo
            }
            return nil
        } catch {
            print("Error on authentication \(error)")
        }
        return nil
    }
    
    func activate(pwd1: String, pwd2: String, token: String) async throws -> Data? {
        let url = Constants.BASE_API_URL
        let header = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        let connection = try await self.post(fullUrl: url + "users/activate/", data: [
            "pwd1":pwd1,
            "pwd2":pwd2,
            "t": token], header: header)
        
        return connection
    }
}
