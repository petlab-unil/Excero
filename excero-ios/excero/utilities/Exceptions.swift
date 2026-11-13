//
//  Exceptions.swift
//  excero
//
//  Created by Alessandro on 23.08.24.
//

import Foundation

public enum ApiError: Error {
    case unauthorizedError(String)
    case serverError(String)
    case defaultApiError(String)
}

enum AuthenticatedApiCallError: Error {
    case emptyToken
    case emptyRefreshToken
    case emptyUserInformation
    case invalidToken(token: String)
    case invalidRefreshToken(token: String)
}

public enum UserException: Error {
    case userDoesNotExist(String)
    case userHasNoURL
}

public enum DataException: Error {
    case conversionException(String)
    case downloadException(String)
    case noLocalDataException(String)
}

public enum NetworkException: Error {
    case networkUnavailableException(String)
}
